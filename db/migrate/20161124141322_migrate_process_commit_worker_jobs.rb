# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateProcessCommitWorkerJobs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Project < ActiveRecord::Base
    def self.find_including_path(id)
      select("projects.*, CONCAT(namespaces.path, '/', projects.path) AS path_with_namespace")
        .joins('INNER JOIN namespaces ON namespaces.id = projects.namespace_id')
        .find_by(id: id)
    end

    def repository_storage_path
      Gitlab.config.repositories.storages[repository_storage].legacy_disk_path
    end

    def repository_path
      # TODO: review if the change from Legacy storage needs to reflect here as well.
      File.join(repository_storage_path, read_attribute(:path_with_namespace) + '.git')
    end

    def repository
      @repository ||= Rugged::Repository.new(repository_path)
    end
  end

  DOWNTIME = true
  DOWNTIME_REASON = 'Existing workers will error until they are using a newer version of the code'

  disable_ddl_transaction!

  def up
    Sidekiq.redis do |redis|
      new_jobs = []

      while job = redis.lpop('queue:process_commit')
        payload = JSON.parse(job)
        project = Project.find_including_path(payload['args'][0])

        next unless project

        begin
          commit = project.repository.lookup(payload['args'][2])
        rescue Rugged::OdbError
          next
        end

        hash = {
          id: commit.oid,
          message: encode(commit.message),
          parent_ids: commit.parent_ids,
          authored_date: commit.author[:time],
          author_name: encode(commit.author[:name]),
          author_email: encode(commit.author[:email]),
          committed_date: commit.committer[:time],
          committer_email: encode(commit.committer[:email]),
          committer_name: encode(commit.committer[:name])
        }

        payload['args'][2] = hash

        new_jobs << JSON.dump(payload)
      end

      redis.multi do |multi|
        new_jobs.each do |j|
          multi.lpush('queue:process_commit', j)
        end
      end
    end
  end

  def down
    Sidekiq.redis do |redis|
      new_jobs = []

      while job = redis.lpop('queue:process_commit')
        payload = JSON.parse(job)

        payload['args'][2] = payload['args'][2]['id']

        new_jobs << JSON.dump(payload)
      end

      redis.multi do |multi|
        new_jobs.each do |j|
          multi.lpush('queue:process_commit', j)
        end
      end
    end
  end

  def encode(data)
    encoding = Encoding::UTF_8

    if data.encoding == encoding
      data
    else
      data.encode(encoding, invalid: :replace, undef: :replace)
    end
  end
end
