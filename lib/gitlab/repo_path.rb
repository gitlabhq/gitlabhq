module Gitlab
  module RepoPath
    NotFoundError = Class.new(StandardError)

    def self.strip_storage_path(repo_path)
      result = nil

      Gitlab.config.repositories.storages.values.each do |params|
        storage_path = params['path']
        if repo_path.start_with?(storage_path)
          result = repo_path.sub(storage_path, '')
          break
        end
      end

      if result.nil?
        raise NotFoundError.new("No known storage path matches #{repo_path.inspect}")
      end

      result.sub(/\A\/*/, '')
    end
  end
end
