# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncDdlExclusiveLeaseGuard
      extend ActiveSupport::Concern
      include ExclusiveLeaseGuard

      def lease_key
        @lease_key ||= "gitlab/database/asyncddl/actions/#{database_config_name}"
      end

      def database_config_name
        connection_db_config.name
      end
    end
  end
end
