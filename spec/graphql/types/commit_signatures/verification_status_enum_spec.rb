# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['VerificationStatus'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('VerificationStatus') }

  it 'exposes all signature verification states' do
    expect(described_class.values.keys)
      .to match_array(Enums::CommitSignature.verification_statuses.map { |status| status.first.to_s.upcase })
  end
end
