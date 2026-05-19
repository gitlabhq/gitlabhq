# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Tag'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('Tag') }

  specify { expect(described_class).to require_graphql_authorizations(:read_code) }

  it 'contains attributes related to tag' do
    expect(described_class).to have_graphql_fields(
      :name, :message, :commit
    )
  end

  describe 'granular token boundary' do
    subject(:boundary_proc) { described_class.granular_token_boundary_procs['project'] }

    let_it_be(:project) { create(:project, :repository) }

    let(:obj) { project.repository.tags.first }

    context 'when the container is a Project' do
      it 'returns the project' do
        expect(boundary_proc.call(obj)).to eq(project)
      end
    end

    context 'when the container is not a Project' do
      let(:group) { build(:group) }

      before do
        allow(obj.repository).to receive(:container).and_return(group)
      end

      it 'returns nil' do
        expect(boundary_proc.call(obj)).to be_nil
      end
    end
  end
end
