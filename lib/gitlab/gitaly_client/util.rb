module Gitlab
  module GitalyClient
    module Util
      class << self
        def repository(repository_storage, relative_path)
          Gitaly::Repository.new(
            storage_name: repository_storage,
            relative_path: relative_path,
            git_object_directory: Gitlab::Git::Env['GIT_OBJECT_DIRECTORY'].to_s,
            git_alternate_object_directories: Array.wrap(Gitlab::Git::Env['GIT_ALTERNATE_OBJECT_DIRECTORIES'])
          )
        end
      end
    end
  end
end
