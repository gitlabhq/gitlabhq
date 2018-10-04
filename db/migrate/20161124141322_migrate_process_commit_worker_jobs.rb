class MigrateProcessCommitWorkerJobs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Repository
    attr_reader :storage

    def initialize(storage, relative_path)
      @storage = storage
      @relative_path = relative_path
    end

    def gitaly_repository
      Gitaly::Repository.new(storage_name: @storage, relative_path: @relative_path)
    end
  end

  class Project < ActiveRecord::Base
    def self.find_including_path(id)
      select("projects.*, CONCAT(namespaces.path, '/', projects.path) AS path_with_namespace")
        .joins('INNER JOIN namespaces ON namespaces.id = projects.namespace_id')
        .find_by(id: id)
    end

    def commit(rev)
      Gitlab::GitalyClient::CommitService.new(repository).find_commit(rev)
    end

    def repository
      @repository ||= Repository.new(repository_storage, read_attribute(:path_with_namespace) + '.git')
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

        commit = project.commit(payload['args'][2])
        next unless commit

        hash = {
          id: commit.id,
          message: encode(commit.body),
          parent_ids: commit.parent_ids.to_a,
          authored_date: Time.at(commit.author.date.seconds).utc,
          author_name: encode(commit.author.name),
          author_email: encode(commit.author.email),
          committed_date: Time.at(commit.committer.date.seconds).utc,
          committer_email: encode(commit.committer.email),
          committer_name: encode(commit.committer.name)
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
