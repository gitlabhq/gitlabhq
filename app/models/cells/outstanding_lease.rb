# frozen_string_literal: true

module Cells
  class OutstandingLease < ApplicationRecord
    self.primary_key = :uuid

    scope :by_uuid, ->(uuid) { where(uuid: uuid) }
    scope :updated_before, ->(time) { where(updated_at: ...time) }

    def self.claim_service
      ::Gitlab::TopologyServiceClient::ClaimService.instance # rubocop:disable CodeReuse/ServiceClass -- this is a gRPC client
    end

    def self.create_from_request!(create_records:, destroy_records:, deadline: nil)
      response = claim_service.begin_update(
        create_records: create_records,
        destroy_records: destroy_records,
        deadline: deadline
      )

      create!(uuid: response.lease_uuid.value)
    end

    def send_commit_update!(deadline: nil)
      self.class.claim_service.commit_update(uuid, deadline: deadline)
    end

    def send_rollback_update!(deadline: nil)
      return unless uuid

      self.class.claim_service.rollback_update(uuid, deadline: deadline)
    end
  end
end
