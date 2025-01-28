# frozen_string_literal: true

require 'gitlab/cells/topology_service'

module Gitlab
  module TopologyServiceClient
    class BaseService
      def initialize
        raise NotImplementedError unless enabled?
      end

      private

      def client
        @client ||= service_class.new(
          topology_service_address,
          service_credentials
        )
      end

      def cell_name
        # This should be removed in
        # https://gitlab.com/gitlab-com/gl-infra/tenant-scale/cells-infrastructure/team/-/issues/60
        # then we should pass cell.id instead
        @cell_name ||= "cell-#{Gitlab.config.cell.id}"
      end

      def service_credentials
        # mTls will be implemented later in Phase 5: https://gitlab.com/groups/gitlab-org/-/epics/14281
        :this_channel_is_insecure
      end

      def topology_service_address
        Gitlab.config.cell.topology_service.address
      end

      def enabled?
        Gitlab.config.topology_service_enabled?
      end
    end
  end
end
