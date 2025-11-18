# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    class ClaimService < BaseService
      include Singleton

      delegate :begin_update, :commit_update, :rollback_update, to: :client

      private

      def service_class
        Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub
      end
    end
  end
end
