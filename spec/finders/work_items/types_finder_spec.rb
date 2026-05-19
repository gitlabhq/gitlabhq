# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::WorkItems::TypesFinder, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:user_project) { create(:project) }
  let_it_be(:group_project) { create(:project, group: group) }

  let_it_be(:system_defined_work_item_type) { build(:work_item_system_defined_type, :issue) }

  subject(:finder) { described_class.new(container: container) }

  context 'when the container is a user namespace' do
    let(:container) { create(:user, :with_namespace).namespace }

    it 'returns empty list' do
      expect(finder.execute).to be_blank
    end
  end

  context 'when the container is a project in user namespace' do
    let(:container) { user_project }

    it_behaves_like 'allowed work item types for a project' do
      subject(:types_list) { finder.execute(only_available: true).map(&:base_type) }
    end

    it_behaves_like 'lists all work item type values' do
      subject(:types_list) { finder.execute(only_available: false).map(&:base_type) }
    end

    it_behaves_like 'lists generally available work item types' do
      subject(:types_list) { finder.execute.map(&:base_type) }
    end

    it_behaves_like 'filtering work item types by existing name' do
      let(:name) { 'issue' }
      subject(:types_list) { finder.execute(name: name, only_available: false).map(&:base_type) }

      context 'and filtering by available' do
        subject(:types_list) do
          finder.execute(name: %w[issue ticket], only_available: true).map(&:base_type)
        end

        it 'returns only the available types from the given names' do
          expect(types_list).to eq(%w[issue ticket])
        end
      end
    end

    it_behaves_like 'filtering work item types by non-existing name' do
      let(:name) { 'unknown' }
      subject(:types_list) { finder.execute(name: name, only_available: false).map(&:base_type) }
    end
  end

  context 'when the container is a project in group namespace' do
    let(:container) { group_project }

    it_behaves_like 'allowed work item types for a project' do
      subject(:types_list) { finder.execute(only_available: true).map(&:base_type) }
    end

    it_behaves_like 'lists all work item type values' do
      subject(:types_list) { finder.execute(only_available: false).map(&:base_type) }
    end

    it_behaves_like 'lists generally available work item types' do
      subject(:types_list) { finder.execute.map(&:base_type) }
    end

    it_behaves_like 'filtering work item types by existing name' do
      let(:name) { 'issue' }
      subject(:types_list) { finder.execute(name: name, only_available: false).map(&:base_type) }

      context 'and filtering by available' do
        subject(:types_list) do
          finder.execute(name: %w[issue ticket], only_available: true).map(&:base_type)
        end

        it 'returns only the available types from the given names' do
          expect(types_list).to eq(%w[issue ticket])
        end
      end
    end

    it_behaves_like 'filtering work item types by non-existing name' do
      let(:name) { 'unknown' }
      subject(:types_list) { finder.execute(name: name, only_available: false).map(&:base_type) }
    end
  end

  context 'when the container is a group' do
    let(:container) { group }

    it_behaves_like 'allowed work item types for a group' do
      subject(:types_list) { finder.execute(only_available: true).map(&:base_type) }
    end

    it_behaves_like 'lists all work item type values' do
      subject(:types_list) { finder.execute(only_available: false).map(&:base_type) }
    end

    it_behaves_like 'lists generally available work item types' do
      subject(:types_list) { finder.execute.map(&:base_type) }
    end

    it_behaves_like 'filtering work item types by existing name' do
      let(:name) { 'issue' }
      subject(:types_list) { finder.execute(name: name, only_available: false).map(&:base_type) }

      context 'and filtering by available' do
        subject(:types_list) do
          finder.execute(name: %w[epic key_result], only_available: true).map(&:base_type)
        end

        # Returns nothing on FOSS as it depends on license
        it 'returns only the available types from the given names' do
          expect(types_list).to eq(%w[])
        end
      end
    end

    it_behaves_like 'filtering work item types by non-existing name' do
      let(:name) { 'unknown' }
      subject(:types_list) { finder.execute(name: name, only_available: false).map(&:base_type) }
    end
  end

  describe 'parameter handling' do
    let(:container) { group_project }
    let(:provider) { ::WorkItems::TypesFramework::Provider.new(container) }

    before do
      allow(::WorkItems::TypesFramework::Provider).to receive(:new).with(container).and_return(provider)
    end

    context 'when only_available is omitted' do
      it 'delegates to the provider#available_types' do
        expect(provider).to receive(:available_types).and_call_original

        finder.execute
      end

      it 'does not delegate to allowed_types, all_ordered_by_name, or filtered_types' do
        expect(provider).not_to receive(:allowed_types)
        expect(provider).not_to receive(:all_ordered_by_name)
        expect(provider).not_to receive(:filtered_types)

        finder.execute
      end
    end

    context 'when only_available is true' do
      it 'delegates to the provider#allowed_types' do
        expect(provider).to receive(:allowed_types).and_call_original

        finder.execute(only_available: true)
      end
    end

    context 'when only_available is false' do
      it 'delegates to the provider#all_ordered_by_name' do
        expect(provider).to receive(:all_ordered_by_name).and_call_original

        finder.execute(only_available: false)
      end
    end
  end
end
