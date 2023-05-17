# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CommitSignature'] do
  it 'exposes the expected fields' do
    expect(described_class).to have_graphql_fields(:verification_status, :commit_sha, :project)
  end

  describe '.resolve_type' do
    it 'resolves gpg signatures' do
      expect(described_class.resolve_type(build(:gpg_signature), {})).to eq(
        Types::CommitSignatures::GpgSignatureType)
    end

    it 'resolves x509 signatures' do
      expect(described_class.resolve_type(build(:x509_commit_signature), {})).to eq(
        Types::CommitSignatures::X509SignatureType)
    end

    it 'resolves SSH signatures' do
      expect(described_class.resolve_type(build(:ssh_signature), {})).to eq(
        Types::CommitSignatures::SshSignatureType)
    end

    it 'raises an error when type is not known' do
      expect { described_class.resolve_type(Class, {}) }.to raise_error('Unsupported commit signature type')
    end
  end
end
