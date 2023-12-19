# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module UserCaching
      SOURCE_USER_CACHE_KEY = 'bitbucket_server/project/%s/source/username/%s'

      def source_user_cache_key(project_id, username)
        format(SOURCE_USER_CACHE_KEY, project_id, username)
      end
    end
  end
end
