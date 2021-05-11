# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:app:check rake task
    module AppTask
      extend RakeTaskHelpers

      def self.name
        'GitLab App'
      end

      def self.checks
        [
          SystemCheck::App::GitConfigCheck,
          SystemCheck::App::DatabaseConfigExistsCheck,
          SystemCheck::App::MigrationsAreUpCheck,
          SystemCheck::App::OrphanedGroupMembersCheck,
          SystemCheck::App::GitlabConfigExistsCheck,
          SystemCheck::App::GitlabConfigUpToDateCheck,
          SystemCheck::App::LogWritableCheck,
          SystemCheck::App::TmpWritableCheck,
          SystemCheck::App::UploadsDirectoryExistsCheck,
          SystemCheck::App::UploadsPathPermissionCheck,
          SystemCheck::App::UploadsPathTmpPermissionCheck,
          SystemCheck::App::InitScriptExistsCheck,
          SystemCheck::App::InitScriptUpToDateCheck,
          SystemCheck::App::ProjectsHaveNamespaceCheck,
          SystemCheck::App::RedisVersionCheck,
          SystemCheck::App::RubyVersionCheck,
          SystemCheck::App::GitVersionCheck,
          SystemCheck::App::GitUserDefaultSSHConfigCheck,
          SystemCheck::App::ActiveUsersCheck,
          SystemCheck::App::AuthorizedKeysPermissionCheck,
          SystemCheck::App::HashedStorageEnabledCheck,
          SystemCheck::App::HashedStorageAllProjectsCheck
        ]
      end
    end
  end
end

SystemCheck::RakeTask::AppTask.prepend_mod_with('SystemCheck::RakeTask::AppTask')
