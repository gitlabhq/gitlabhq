# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Tree::TreeType do
  specify { expect(described_class.graphql_name).to eq('Tree') }

  specify { expect(described_class).to have_graphql_fields(:trees, :submodules, :blobs, :last_commit, :permalink_path) }

  describe 'granular token boundary' do
    subject(:boundary_proc) { described_class.granular_token_boundary_procs['project'] }

    let_it_be(:project) { create(:project, :repository) }

    let(:repository) { project.repository }

    context 'when the repository is present' do
      let(:obj) { instance_double(Tree, repository: repository) }

      it 'returns the project' do
        expect(boundary_proc.call(obj)).to eq(project)
      end
    end

    context 'when the repository is nil' do
      let(:obj) { instance_double(Tree, repository: nil) }

      it 'returns nil' do
        expect(boundary_proc.call(obj)).to be_nil
      end
    end
  end
end
