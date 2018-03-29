require 'spec_helper'

describe Boards::DestroyService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }

    shared_examples 'remove the board' do |parent_name|
      let(:parent) { public_send(parent_name) }
      let!(:board) { create(:board, parent_name => parent) }

      subject(:service) { described_class.new(parent, double) }

      context "when #{parent_name} have more than one board" do
        it "removes board from #{parent_name}" do
          create(:board, parent_name => parent)

          expect { service.execute(board) }.to change(parent.boards, :count).by(-1)
        end
      end

      context "when #{parent_name} have one board" do
        it "does not remove board from #{parent_name}" do
          expect { service.execute(board) }.not_to change(group.boards, :count)
        end
      end
    end

    it_behaves_like 'remove the board', :group
    it_behaves_like 'remove the board', :project
  end
end
