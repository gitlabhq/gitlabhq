# frozen_string_literal: true

module Cells
  class OutstandingLease < ApplicationRecord
    self.primary_key = :uuid

    def self.claim_service
      ::Gitlab::TopologyServiceClient::ClaimService.instance # rubocop:disable CodeReuse/ServiceClass -- this is a gRPC client
    end

    def self.create_from_request!(create_records:, destroy_records:, deadline: nil)
      req = Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
        create_records: create_records,
        destroy_records: destroy_records,
        cell_id: claim_service.cell_id
      )

      res = claim_service.begin_update(req, deadline: deadline)

      create!(uuid: res.lease_uuid.value)
    end

    def send_commit_update!(deadline: nil)
      req = Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid),
        cell_id: self.class.claim_service.cell_id
      )

      self.class.claim_service.commit_update(req, deadline: deadline)
    end

    def send_rollback_update!(deadline: nil)
      return unless uuid

      req = Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid),
        cell_id: self.class.claim_service.cell_id
      )

      self.class.claim_service.rollback_update(req, deadline: deadline)
    end
  end
end
