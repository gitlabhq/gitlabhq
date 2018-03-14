require 'spec_helper'

describe Boards::ListService do
  shared_examples 'boards list service' do
    let(:service) { described_class.new(parent, double) }
    before do
      create_list(:board, 2, parent: parent)
    end

    describe '#execute' do
      it 'returns all issue boards when multiple issue boards is enabled' do
        if parent.is_a?(Group)
          stub_licensed_features(multiple_group_issue_boards: true)
        end

        expect(service.execute.size).to eq(2)
      end

      it 'returns the first issue board when multiple issue boards is disabled' do
        if parent.is_a?(Project)
          stub_licensed_features(multiple_project_issue_boards: false)
        end

        expect(service.execute.size).to eq(1)
      end
    end
  end

  it_behaves_like 'boards list service' do
    let(:parent) { create(:project, :empty_repo) }
  end

  it_behaves_like 'boards list service' do
    let(:parent) { create(:group) }
  end
end
