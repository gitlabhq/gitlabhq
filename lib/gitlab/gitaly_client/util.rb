# frozen_string_literal: true

module Gitlab
  module GitalyClient
    module Util
      class << self
        def repository(repository_storage, relative_path, gl_repository, gl_project_path)
          git_env = Gitlab::Git::HookEnv.all(gl_repository)
          git_object_directory = git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].presence
          git_alternate_object_directories = Array.wrap(git_env['GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE'])

          Gitaly::Repository.new(
            storage_name: repository_storage,
            relative_path: relative_path,
            gl_repository: gl_repository.to_s,
            git_object_directory: git_object_directory.to_s,
            git_alternate_object_directories: git_alternate_object_directories,
            gl_project_path: gl_project_path
          )
        end

        def git_repository(gitaly_repository)
          Gitlab::Git::Repository.new(gitaly_repository.storage_name,
            gitaly_repository.relative_path,
            gitaly_repository.gl_repository,
            gitaly_repository.gl_project_path)
        end
      end
    end
  end
end
