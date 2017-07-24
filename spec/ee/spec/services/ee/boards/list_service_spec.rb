require 'spec_helper'

describe Boards::ListService do
  let(:project) { create(:empty_project) }
  let(:service) { described_class.new(project, double) }

  before do
    create_list(:board, 2, project: project)
  end

  describe '#execute' do
    it 'returns all issue boards when `multiple_issue_boards` is enabled' do
      stub_licensed_features(multiple_issue_boards: true)

      expect(service.execute.size).to eq(2)
    end

    it 'returns the first issue board when `multiple_issue_boards` is disabled' do
      stub_licensed_features(multiple_issue_boards: false)

      expect(service.execute.size).to eq(1)
    end
  end
end
