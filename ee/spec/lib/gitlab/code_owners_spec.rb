# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeOwners do
  include FakeBlobHelpers

  let!(:code_owner) { create(:user, username: 'owner-1') }
  let(:project) { create(:project, :repository) }
  let(:blob) do
    project.repository.blob_at(TestEnv::BRANCH_SHA['with-codeowners'], 'docs/CODEOWNERS')
  end
  let(:codeowner_content) { "docs/CODEOWNERS @owner-1" }
  let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }

  before do
    project.add_developer(code_owner)
    allow(project.repository).to receive(:code_owners_blob).and_return(codeowner_blob)
  end

  describe '.for_blob' do
    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns users for a blob' do
        expect(described_class.for_blob(blob)).to include(code_owner)
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns no users' do
        expect(described_class.for_blob(blob)).to be_empty
      end
    end
  end
end
