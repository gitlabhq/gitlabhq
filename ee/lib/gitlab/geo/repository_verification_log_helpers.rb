module Gitlab
  module Geo
    module RepositoryVerificationLogHelpers
      include ProjectLogHelpers

      protected

      def geo_logger
        Gitlab::Geo::RepositoryVerificationLogger
      end
    end
  end
end
