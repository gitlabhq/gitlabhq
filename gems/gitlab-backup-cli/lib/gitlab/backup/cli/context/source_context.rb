# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Context
        # This context is equivalent to a Source Install or GDK instance
        #
        # Any specific information from the GitLab installation will be
        # automatically discovered from the current machine
        class SourceContext
          # Defaults defined in `config/initializers/1_settings.rb`
          DEFAULT_SHARED_PATH = 'shared'
          DEFAULT_CI_BUILDS_PATH = 'builds'
          DEFAULT_JOBS_ARTIFACTS_PATH = 'artifacts'
          DEFAULT_SECURE_FILES_PATH = 'ci_secure_files'
          DEFAULT_CI_LFS_PATH = 'lfs-objects'
          DEFAULT_PACKAGES = 'packages'
          DEFAULT_PAGES = 'pages'
          DEFAULT_REGISTRY_PATH = 'registry'
          DEFAULT_TERRAFORM_STATE_PATH = 'terraform_state'
          DEFAULT_UPLOADS_PATH = 'public' # based on GitLab's root folder

          def gitlab_version
            File.read(gitlab_basepath.join("VERSION")).strip.freeze
          end

          def backup_basedir
            path = gitlab_config[env]['backup']['path']

            absolute_path(path)
          end

          # CI Builds basepath
          def ci_builds_path
            path = gitlab_config.dig(env, 'gitlab_ci', 'builds_path') || DEFAULT_CI_BUILDS_PATH

            absolute_path(path)
          end

          # Job Artifacts basepath
          def ci_job_artifacts_path
            path = gitlab_config.dig(env, 'artifacts', 'path') ||
              gitlab_config.dig(env, 'artifacts', 'storage_path') ||
              gitlab_shared_path.join(DEFAULT_JOBS_ARTIFACTS_PATH)

            absolute_path(path)
          end

          # CI Secure Files basepath
          def ci_secure_files_path
            path = gitlab_config.dig(env, 'ci_secure_files', 'storage_path') ||
              gitlab_shared_path.join(DEFAULT_SECURE_FILES_PATH)

            absolute_path(path)
          end

          # CI LFS basepath
          def ci_lfs_path
            path = gitlab_config.dig(env, 'lfs', 'storage_path') ||
              gitlab_shared_path.join(DEFAULT_CI_LFS_PATH)

            absolute_path(path)
          end

          # Packages basepath
          def packages_path
            path = gitlab_config.dig(env, 'packages', 'storage_path') ||
              gitlab_shared_path.join(DEFAULT_PACKAGES)

            absolute_path(path)
          end

          # GitLab Pages basepath
          def pages_path
            path = gitlab_config.dig(env, 'pages', 'path') ||
              gitlab_shared_path.join(DEFAULT_PAGES)

            absolute_path(path)
          end

          # Registry basepath
          def registry_path
            path = gitlab_config.dig(env, 'registry', 'path') ||
              gitlab_shared_path.join(DEFAULT_REGISTRY_PATH)

            absolute_path(path)
          end

          # Terraform State basepath
          def terraform_state_path
            path = gitlab_config.dig(env, 'terraform_state', 'storage_path') ||
              gitlab_shared_path.join(DEFAULT_TERRAFORM_STATE_PATH)

            absolute_path(path)
          end

          # Upload basepath
          def upload_path
            path = gitlab_config.dig(env, 'uploads', 'storage_path') ||
              gitlab_basepath.join(DEFAULT_UPLOADS_PATH)

            absolute_path(path).join('uploads')
          end

          def database_config_file_path
            gitlab_basepath.join('config/database.yml')
          end

          def config(object_type)
            gitlab_config[object_type]
          end

          def env
            @env ||= ActiveSupport::EnvironmentInquirer.new(
              ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence || "development")
          end

          def config_repositories_storages
            gitlab_config.dig(env, 'repositories', 'storages')
          end

          def gitaly_backup_path
            gitlab_config.dig(env, 'backup', 'gitaly_backup_path')
          end

          def gitaly_token
            gitlab_config.dig(env, 'gitaly', 'token')
          end

          # Return the GitLab base directory
          # @return [Pathname]
          def gitlab_basepath
            return Pathname.new(GITLAB_PATH) if GITLAB_PATH

            raise ::Gitlab::Backup::Cli::Error, 'GITLAB_PATH is missing'
          end

          private

          # Return the shared path used as a fallback base location to each blob type
          # We use this to determine the storage location when everything else fails
          # @return [Pathname]
          def gitlab_shared_path
            shared_path = gitlab_config.dig(env, 'shared', 'path') || DEFAULT_SHARED_PATH

            Pathname(shared_path)
          end

          # Return a fullpath for a given path
          #
          # When the path is already a full one return itself as a Pathname
          # otherwise uses gitlab_basepath as its base
          # @param [String|Pathname] path
          # @return [Pathname]
          def absolute_path(path)
            # Joins with gitlab_basepath when relative, otherwise return full path
            Pathname(File.expand_path(path, gitlab_basepath))
          end

          def gitlab_config
            return @gitlab_config unless @gitlab_config.nil?

            @gitlab_config ||= build_gitlab_config.then do |config|
              raise ::Gitlab::Backup::Cli::Error, 'Failed to load GitLab configuration file' unless config.loaded?

              config
            end
          end

          def build_gitlab_config
            Gitlab::Backup::Cli::GitlabConfig.new(gitlab_basepath.join('config/gitlab.yml'))
          end
        end
      end
    end
  end
end
