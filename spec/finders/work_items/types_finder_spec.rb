# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::WorkItems::TypesFinder, feature_category: :team_planning do
  subject(:finder) { described_class.new(container: container) }

  context 'when the container is a user namespace' do
    let_it_be(:container) { create(:user).namespace }

    it 'returns empty list' do
      expect(finder.execute).to be_blank
    end
  end

  context 'when the container is a project' do
    let_it_be(:container) { create(:project) }

    it_behaves_like 'allowed work item types for a project' do
      subject(:types_list) { finder.execute.map(&:base_type) }
    end

    it_behaves_like 'lists all work item type values' do
      subject(:types_list) { finder.execute(list_all: true).map(&:base_type) }
    end

    it_behaves_like 'filtering work item types by existing name' do
      let(:name) { 'issue' }
      subject(:types_list) { finder.execute(name: name).map(&:base_type) }
    end

    it_behaves_like 'filtering work item types by non-existing name' do
      let(:name) { 'unknown' }
      subject(:types_list) { finder.execute(name: name).map(&:base_type) }
    end
  end

  context 'when the container is a group' do
    let_it_be(:container) { create(:group) }

    it_behaves_like 'allowed work item types for a group' do
      subject(:types_list) { finder.execute.map(&:base_type) }
    end

    it_behaves_like 'lists all work item type values' do
      subject(:types_list) { finder.execute(list_all: true).map(&:base_type) }
    end

    it_behaves_like 'filtering work item types by existing name' do
      let(:name) { 'issue' }
      subject(:types_list) { finder.execute(name: name).map(&:base_type) }
    end

    it_behaves_like 'filtering work item types by non-existing name' do
      let(:name) { 'unknown' }
      subject(:types_list) { finder.execute(name: name).map(&:base_type) }
    end
  end
end
