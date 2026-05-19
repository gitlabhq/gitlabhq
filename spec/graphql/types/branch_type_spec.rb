# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Branch'], feature_category: :source_code_management do
  it { expect(described_class.graphql_name).to eq('Branch') }

  it { expect(described_class).to have_graphql_fields(:name, :commit) }

  describe 'granular token boundary' do
    subject(:boundary_proc) { described_class.granular_token_boundary_procs['project'] }

    let_it_be(:project) { create(:project, :repository) }

    let(:obj) { project.repository.find_branch('master') }

    context 'when the container is a Project' do
      it 'returns the project' do
        expect(boundary_proc.call(obj)).to eq(project)
      end
    end

    context 'when the container is not a Project' do
      let(:group) { build(:group) }

      before do
        allow(obj.dereferenced_target.repository).to receive(:container).and_return(group)
      end

      it 'returns nil' do
        expect(boundary_proc.call(obj)).to be_nil
      end
    end

    context 'when dereferenced_target is nil' do
      before do
        allow(obj).to receive(:dereferenced_target).and_return(nil)
      end

      it 'returns nil' do
        expect(boundary_proc.call(obj)).to be_nil
      end
    end
  end
end
