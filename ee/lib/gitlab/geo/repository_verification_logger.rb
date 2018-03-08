module Gitlab
  module Geo
    class RepositoryVerificationLogger < ::Gitlab::Geo::Logger
      def self.file_name_noext
        'geo_repository_verification'
      end
    end
  end
end
