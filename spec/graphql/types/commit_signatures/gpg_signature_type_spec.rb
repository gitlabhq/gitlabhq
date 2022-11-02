# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GpgSignature'] do
  specify { expect(described_class.graphql_name).to eq('GpgSignature') }

  specify { expect(described_class).to require_graphql_authorizations(:download_code) }

  specify { expect(described_class).to include(Types::CommitSignatureInterface) }

  it 'contains attributes related to GPG signatures' do
    expect(described_class).to have_graphql_fields(
      :user, :verification_status, :commit_sha, :project,
      :gpg_key_user_name, :gpg_key_user_email, :gpg_key_primary_keyid
    )
  end
end
