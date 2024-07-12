# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ImportSourceUserStatus'], feature_category: :importers do
  specify { expect(described_class.graphql_name).to eq('ImportSourceUserStatus') }

  describe 'statuses' do
    it 'exposes a status with the correct value' do
      expect(described_class.values.keys).to match_array(
        %w[
          AWAITING_APPROVAL
          COMPLETED
          FAILED
          KEEP_AS_PLACEHOLDER
          PENDING_REASSIGNMENT
          REASSIGNMENT_IN_PROGRESS
          REJECTED
        ]
      )
    end
  end
end
