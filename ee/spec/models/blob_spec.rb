# frozen_string_literal: true

require 'spec_helper'

describe Blob do
  let(:project) { create(:project, :repository) }
  let(:blob) do
    project.repository.blob_at(TestEnv::BRANCH_SHA['with-codeowners'], 'docs/CODEOWNERS')
  end
  let(:code_owner) { create(:user, username: 'documentation-owner') }

  before do
    project.add_developer(code_owner)
  end

  describe '#owners' do
    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns the owners from the file' do
        expect(blob.owners).to include(code_owner)
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns no code owners' do
        expect(blob.owners).to be_empty
      end
    end
  end
end
