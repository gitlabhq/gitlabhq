module Gitlab
  module GitalyClient
    module Util
      class << self
        def repository(repository_storage, relative_path)
          Gitaly::Repository.new(
            storage_name: repository_storage,
            relative_path: relative_path
          )
        end
      end
    end
  end
end
