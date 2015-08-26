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
        expose :id, :commands, :path, :ref, :sha, :project_id, :repo_url,
          :before_sha, :timeout, :allow_git_fetch, :project_name, :options

        expose :variables
      end

      class Runner < Grape::Entity
        expose :id, :token
      end

      class Project < Grape::Entity
        expose :id, :name, :timeout, :token, :default_ref, :gitlab_url, :path,
          :always_build, :polling_interval, :public, :ssh_url_to_repo, :gitlab_id
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
