module Gitlab
  module GitalyClient
    module Util
      class << self
        def self.process_path(repository_storage, relative_path)
          [channel(repository_storage), repository(repository_storage, relative_path)]
        end

        def repository(repository_storage, relative_path)
          Gitaly::Repository.new(
            path: File.join(Gitlab.config.repositories.storages[repository_storage]['path'], relative_path),
            storage_name: repository_storage,
            relative_path: relative_path,
          )
        end

        def channel(repository_storage)
          GitalyClient.get_channel(repository_storage)
        end
      end
    end
  end
end
