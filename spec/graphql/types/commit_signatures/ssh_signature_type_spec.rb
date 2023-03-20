# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SshSignature'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('SshSignature') }

  specify { expect(described_class).to require_graphql_authorizations(:download_code) }

  specify { expect(described_class).to include(Types::CommitSignatureInterface) }

  it 'contains attributes related to SSH signatures' do
    expect(described_class).to have_graphql_fields(
      :user, :verification_status, :commit_sha, :project, :key, :key_fingerprint_sha256
    )
  end
end
