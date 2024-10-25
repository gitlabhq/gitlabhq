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
        @cell_name ||= Gitlab.config.cell.name
      end

      def service_credentials
        # mTls will be implemented later in Phase 5: https://gitlab.com/groups/gitlab-org/-/epics/14281
        :this_channel_is_insecure
      end

      def topology_service_address
        Gitlab.config.topology_service.address
      end

      def enabled?
        Gitlab.config.topology_service.respond_to?(:enabled) && Gitlab.config.topology_service.enabled &&
          Gitlab.config.cell.respond_to?(:name) && cell_name.present?
      end
    end
  end
end
