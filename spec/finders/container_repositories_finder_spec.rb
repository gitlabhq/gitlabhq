# frozen_string_literal: true

require 'spec_helper'

describe ContainerRepositoriesFinder do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:project_repository) { create(:container_repository, project: project) }

  describe '#execute' do
    let(:id) { nil }

    subject { described_class.new(id: id, container_type: container_type).execute }

    context 'when container_type is group' do
      let(:other_project) { create(:project, group: group) }

      let(:other_repository) do
        create(:container_repository, name: 'test_repository2', project: other_project)
      end

      let(:container_type) { :group }
      let(:id) { group.id }

      it { is_expected.to match_array([project_repository, other_repository]) }
    end

    context 'when container_type is project' do
      let(:container_type) { :project }
      let(:id) { project.id }

      it { is_expected.to match_array([project_repository]) }
    end

    context 'with invalid id' do
      let(:container_type) { :project }
      let(:id) { 123456789 }

      it 'raises an error' do
        expect { subject.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
