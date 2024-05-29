# frozen_string_literal: true

module Gitlab
  module Cng
    module Helpers
      # Helper functions for fetching CI related information
      #
      module CI
        extend self

        def commit_sha
          @commit_sha ||= ENV["CI_COMMIT_SHA"] || raise("CI_COMMIT_SHA is not set")
        end

        def commit_short_sha
          @commit_short_sha ||= ENV["CI_COMMIT_SHORT_SHA"] || raise("CI_COMMIT_SHORT_SHA is not set")
        end

        def gitaly_version
          @gitaly_version ||= File.read(File.join(ci_project_dir, "GITALY_SERVER_VERSION")).strip
        end

        def gitlab_shell_version
          @gitlab_shell_version ||= File.read(File.join(ci_project_dir, "GITLAB_SHELL_VERSION")).strip
        end

        def ci_project_dir
          @ci_project_dir ||= ENV["CI_PROJECT_DIR"] || raise("CI_PROJECT_DIR is not set")
        end
      end
    end
  end
end
