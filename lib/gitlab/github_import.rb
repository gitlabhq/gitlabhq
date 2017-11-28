module Gitlab
  module GithubImport
    def self.refmap
      [:heads, :tags, '+refs/pull/*/head:refs/merge-requests/*/head']
    end

    def self.new_client_for(project, token: nil, parallel: true)
      token_to_use = token || project.import_data&.credentials&.fetch(:user)

      Client.new(token_to_use, parallel: parallel)
    end

    # Inserts a raw row and returns the ID of the inserted row.
    #
    # attributes - The attributes/columns to set.
    # relation - An ActiveRecord::Relation to use for finding the ID of the row
    #            when using MySQL.
    def self.insert_and_return_id(attributes, relation)
      # We use bulk_insert here so we can bypass any queries executed by
      # callbacks or validation rules, as doing this wouldn't scale when
      # importing very large projects.
      result = Gitlab::Database
        .bulk_insert(relation.table_name, [attributes], return_ids: true)

      # MySQL doesn't support returning the IDs of a bulk insert in a way that
      # is not a pain, so in this case we'll issue an extra query instead.
      result.first ||
        relation.where(iid: attributes[:iid]).limit(1).pluck(:id).first
    end

    # Returns the ID of the ghost user.
    def self.ghost_user_id
      key = 'github-import/ghost-user-id'

      Caching.read_integer(key) || Caching.write(key, User.select(:id).ghost.id)
    end
  end
end
