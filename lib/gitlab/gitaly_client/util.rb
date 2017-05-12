module Gitlab
  module GitalyClient
    module Util
      class << self
        def repository(repository_storage, relative_path)
          Gitaly::Repository.new(
            path: File.join(Gitlab.config.repositories.storages[repository_storage]['path'], relative_path),
            storage_name: repository_storage,
            relative_path: relative_path
          )
        end
      end
    end
  end
end
