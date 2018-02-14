module Gitlab
  module Geo
    class RepoSyncRequest < BaseRequest
      def expiration_time
        10.minutes
      end
    end
  end
end
