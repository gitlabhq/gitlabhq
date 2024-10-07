# frozen_string_literal: true

module Gitlab
  module Database
    ##
    # This class is used to make it possible to ensure read consistency in
    # GitLab without the need of overriding a lot of methods / classes /
    # classs.
    #
    class Consistency
      ##
      # Within the block, disable the database load balancing for calls that
      # require read consistency after recent writes.
      #
      def self.with_read_consistency(&block)
        ::Gitlab::Database::LoadBalancing::SessionMap
          .with_sessions(Gitlab::Database::LoadBalancing.base_models)
          .use_primary(&block)
      end
    end
  end
end
