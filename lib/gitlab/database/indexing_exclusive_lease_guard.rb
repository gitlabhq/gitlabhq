# frozen_string_literal: true

module Gitlab
  module Database
    module IndexingExclusiveLeaseGuard
      extend ActiveSupport::Concern
      include ExclusiveLeaseGuard

      def lease_key
        @lease_key ||= "gitlab/database/indexing/actions/#{database_config_name}"
      end

      def database_config_name
        Gitlab::Database.db_config_name(connection)
      end
    end
  end
end
