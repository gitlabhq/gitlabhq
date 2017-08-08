require 'spec_helper'

describe Boards::CreateService, services: true do
  shared_examples 'boards create service' do
    context 'With the feature available' do
      before do
        stub_licensed_features(multiple_issue_boards: true)
      end

      context 'with valid params' do
        subject(:service) { described_class.new(parent, double, name: 'Backend') }

        it 'creates a new board' do
          expect { service.execute }.to change(parent.boards, :count).by(1)
        end

        it 'creates the default lists' do
          board = service.execute

          expect(board.lists.size).to eq 2
          expect(board.lists.first).to be_backlog
          expect(board.lists.last).to be_closed
        end
      end

      context 'with invalid params' do
        subject(:service) { described_class.new(parent, double, name: nil) }

        it 'does not create a new parent board' do
          expect { service.execute }.not_to change(parent.boards, :count)
        end

        it "does not create board's default lists" do
          board = service.execute

          expect(board.lists.size).to eq 0
        end
      end

      context 'without params' do
        subject(:service) { described_class.new(parent, double) }

        it 'creates a new parent board' do
          expect { service.execute }.to change(parent.boards, :count).by(1)
        end

        it "creates board's default lists" do
          board = service.execute

          expect(board.lists.size).to eq 2
          expect(board.lists.last).to be_closed
        end
      end
    end

    it 'skips creating a second board when the feature is not available' do
      stub_licensed_features(multiple_issue_boards: false)
      service = described_class.new(parent, double)

      expect(service.execute).not_to be_nil

      expect { service.execute }.not_to change(parent.boards, :count)
    end
  end

  describe '#execute' do
    it_behaves_like 'boards create service' do
      let(:parent) { create(:project, :empty_repo) }
    end

    it_behaves_like 'boards create service' do
      let(:parent) { create(:group) }
    end
  end
end
