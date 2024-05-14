# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        autoload :Artifacts, 'gitlab/backup/cli/tasks/artifacts'
        autoload :Builds, 'gitlab/backup/cli/tasks/builds'
        autoload :CiSecureFiles, 'gitlab/backup/cli/tasks/ci_secure_files'
        autoload :Database, 'gitlab/backup/cli/tasks/database'
        autoload :Lfs, 'gitlab/backup/cli/tasks/lfs'
        autoload :Registry, 'gitlab/backup/cli/tasks/registry'
        autoload :Repositories, 'gitlab/backup/cli/tasks/repositories'
        autoload :Packages, 'gitlab/backup/cli/tasks/packages'
        autoload :Pages, 'gitlab/backup/cli/tasks/pages'
        autoload :Task, 'gitlab/backup/cli/tasks/task'
        autoload :TerraformState, 'gitlab/backup/cli/tasks/terraform_state'
        autoload :Uploads, 'gitlab/backup/cli/tasks/uploads'

        TASKS = {
          Gitlab::Backup::Cli::Tasks::Database.id => Gitlab::Backup::Cli::Tasks::Database,
          Gitlab::Backup::Cli::Tasks::Repositories.id => Gitlab::Backup::Cli::Tasks::Repositories,
          Gitlab::Backup::Cli::Tasks::Uploads.id => Gitlab::Backup::Cli::Tasks::Uploads,
          Gitlab::Backup::Cli::Tasks::Builds.id => Gitlab::Backup::Cli::Tasks::Builds,
          Gitlab::Backup::Cli::Tasks::Artifacts.id => Gitlab::Backup::Cli::Tasks::Artifacts,
          Gitlab::Backup::Cli::Tasks::Pages.id => Gitlab::Backup::Cli::Tasks::Pages,
          Gitlab::Backup::Cli::Tasks::Lfs.id => Gitlab::Backup::Cli::Tasks::Lfs,
          Gitlab::Backup::Cli::Tasks::TerraformState.id => Gitlab::Backup::Cli::Tasks::TerraformState,
          Gitlab::Backup::Cli::Tasks::Registry.id => Gitlab::Backup::Cli::Tasks::Registry,
          Gitlab::Backup::Cli::Tasks::Packages.id => Gitlab::Backup::Cli::Tasks::Packages,
          Gitlab::Backup::Cli::Tasks::CiSecureFiles.id => Gitlab::Backup::Cli::Tasks::CiSecureFiles
        }.freeze

        def self.all
          TASKS.values
        end

        def self.build_each(**init_args)
          return enum_for(__method__, **init_args) unless block_given?

          all.each do |task_class|
            yield(task_class.new(**init_args))
          end
        end
      end
    end
  end
end
