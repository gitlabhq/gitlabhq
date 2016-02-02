require 'base64'
require 'json'

module Gitlab
  class Workhorse
    class << self
      def send_git_blob(repository, blob)
        params_hash = {
          'RepoPath' => repository.path_to_repo,
          'BlobId' => blob.id,
        }
        params = Base64.urlsafe_encode64(JSON.dump(params_hash))

        [
          'Gitlab-Workhorse-Send-Data',
          "git-blob:#{params}",
        ]
      end
    end
  end
end
