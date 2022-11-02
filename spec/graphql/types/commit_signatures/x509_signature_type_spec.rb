# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['X509Signature'] do
  specify { expect(described_class.graphql_name).to eq('X509Signature') }

  specify { expect(described_class).to require_graphql_authorizations(:download_code) }

  specify { expect(described_class).to include(Types::CommitSignatureInterface) }

  it 'contains attributes related to X.509 signatures' do
    expect(described_class).to have_graphql_fields(
      :user, :verification_status, :commit_sha, :project,
      :x509_certificate
    )
  end
end
