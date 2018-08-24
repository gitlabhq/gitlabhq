module Gitlab
  module GithubImport
    def self.refmap
      [:heads, :tags, '+refs/pull/*/head:refs/merge-requests/*/head']
    end

    def self.new_client_for(project, token: nil, parallel: true)
      token_to_use = token || project.import_data&.credentials&.fetch(:user)

      Client.new(token_to_use, parallel: parallel)
    end

    # Returns the ID of the ghost user.
    def self.ghost_user_id
      key = 'github-import/ghost-user-id'

      Caching.read_integer(key) || Caching.write(key, User.select(:id).ghost.id)
    end
  end
end
