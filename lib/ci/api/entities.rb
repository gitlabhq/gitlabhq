module Ci
  module API
    module Entities
      class Commit < Grape::Entity
        expose :id, :ref, :sha, :project_id, :before_sha, :created_at
        expose :status, :finished_at, :duration
        expose :git_commit_message, :git_author_name, :git_author_email
      end

      class CommitWithBuilds < Commit
        expose :builds
      end

      class Build < Grape::Entity
        expose :id, :commands, :ref, :sha, :project_id, :repo_url,
          :before_sha, :allow_git_fetch, :project_name

        expose :options do |model|
          model.options
        end

        expose :timeout do |model|
          model.timeout
        end

        expose :variables
      end

      class Runner < Grape::Entity
        expose :id, :token
      end

      class Project < Grape::Entity
        expose :id, :name, :token, :default_ref, :gitlab_url, :path,
          :always_build, :polling_interval, :public, :ssh_url_to_repo, :gitlab_id

        expose :timeout do |model|
          model.timeout
        end
      end

      class RunnerProject < Grape::Entity
        expose :id, :project_id, :runner_id
      end

      class WebHook < Grape::Entity
        expose :id, :project_id, :url
      end

      class TriggerRequest < Grape::Entity
        expose :id, :variables
        expose :commit, using: Commit
      end
    end
  end
end
