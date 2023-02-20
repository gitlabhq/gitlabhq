# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['VerificationStatus'] do
  specify { expect(described_class.graphql_name).to eq('VerificationStatus') }

  it 'exposes all signature verification states' do
    expect(described_class.values.keys)
      .to match_array(%w[
                        UNVERIFIED UNVERIFIED_KEY VERIFIED
                        SAME_USER_DIFFERENT_EMAIL OTHER_USER UNKNOWN_KEY
                        MULTIPLE_SIGNATURES REVOKED_KEY
                      ])
  end
end
