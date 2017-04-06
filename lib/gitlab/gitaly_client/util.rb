module Gitlab
  module GitalyClient
    module Util
      def self.process_path(repository_storage, relative_path)
        channel = GitalyClient.get_channel(repository_storage)
        storage_path = Gitlab.config.repositories.storages[repository_storage]['path']
        repository = Gitaly::Repository.new(path: File.join(storage_path, relative_path))

        [channel, repository]
      end
    end
  end
end
