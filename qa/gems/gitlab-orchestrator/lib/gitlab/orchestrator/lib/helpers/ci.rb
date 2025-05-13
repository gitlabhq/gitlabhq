# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Helpers
      # Helper functions for fetching CI related information
      #
      module CI
        extend self

        def ci_project_dir
          @ci_project_dir ||= ENV["CI_PROJECT_DIR"] || raise("CI_PROJECT_DIR is not set")
        end

        def commit_sha
          @commit_sha ||= ENV["CI_COMMIT_SHA"] || raise("CI_COMMIT_SHA is not set")
        end

        def commit_short_sha
          @commit_short_sha ||= ENV["CI_COMMIT_SHORT_SHA"] || raise("CI_COMMIT_SHORT_SHA is not set")
        end

        def gitaly_version
          @gitaly_version ||= ENV["GITALY_TAG"].presence || File.read(
            File.join(ci_project_dir, "GITALY_SERVER_VERSION")
          ).strip
        end

        def gitlab_shell_version
          @gitlab_shell_version ||= ENV["GITLAB_SHELL_TAG"].presence || File.read(
            File.join(ci_project_dir, "GITLAB_SHELL_VERSION")
          ).strip
        end

        def sidekiq_version
          @sidekiq_version ||= ENV["GITLAB_SIDEKIQ_TAG"].presence || commit_sha
        end

        def toolbox_version
          @toolbox_version ||= ENV["GITLAB_TOOLBOX_TAG"].presence || commit_sha
        end

        def webservice_version
          @webservice_version ||= ENV["GITLAB_WEBSERVICE_TAG"].presence || commit_sha
        end

        def workhorse_version
          @workhorse_version ||= ENV["GITLAB_WORKHORSE_TAG"].presence || commit_sha
        end

        def kas_version
          @kas_version ||= ENV["GITLAB_KAS_TAG"].presence || File.read(
            File.join(ci_project_dir, "GITLAB_KAS_VERSION")
          ).strip
        end

        def registry_version
          @registry_version ||= ENV["GITLAB_CONTAINER_REGISTRY_TAG"].presence || commit_sha
        end
      end
    end
  end
end
