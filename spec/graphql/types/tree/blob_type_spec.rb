# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Tree::BlobType do
  specify { expect(described_class.graphql_name).to eq('Blob') }

  specify { expect(described_class).to have_graphql_fields(:id, :sha, :name, :type, :path, :flat_path, :web_url, :web_path, :lfs_oid, :mode) }

  describe 'granular token boundary' do
    subject(:boundary_proc) { described_class.granular_token_boundary_procs['project'] }

    let_it_be(:project) { create(:project, :repository) }

    let(:repository) { project.repository }

    context 'when the repository is present' do
      let(:obj) do
        Gitlab::Graphql::Representation::TreeEntry.new(repository.tree.blobs.first, repository)
      end

      it 'returns the project' do
        expect(boundary_proc.call(obj)).to eq(project)
      end
    end

    context 'when the repository is nil' do
      let(:obj) do
        Gitlab::Graphql::Representation::TreeEntry.new(repository.tree.blobs.first, nil)
      end

      it 'returns nil' do
        expect(boundary_proc.call(obj)).to be_nil
      end
    end
  end
end
