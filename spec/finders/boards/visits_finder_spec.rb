# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::VisitsFinder do
  describe '#latest' do
    let(:user) { create(:user) }

    context 'when a project board' do
      let(:project)       { create(:project) }
      let(:project_board) { create(:board, project: project) }

      subject(:finder) { described_class.new(project_board.resource_parent, user) }

      it 'returns nil when there is no user' do
        finder.current_user = nil

        expect(finder.execute).to eq nil
      end

      it 'queries for most recent visit' do
        expect(BoardProjectRecentVisit).to receive(:latest).once

        finder.execute
      end

      it 'queries for last N visits' do
        expect(BoardProjectRecentVisit).to receive(:latest).with(user, project, count: 5).once

        described_class.new(project_board.resource_parent, user).latest(5)
      end
    end

    context 'when a group board' do
      let(:group)       { create(:group) }
      let(:group_board) { create(:board, group: group) }

      subject(:finder) { described_class.new(group_board.resource_parent, user) }

      it 'returns nil when there is no user' do
        finder.current_user = nil

        expect(finder.execute).to eq nil
      end

      it 'queries for most recent visit' do
        expect(BoardGroupRecentVisit).to receive(:latest).once

        finder.latest
      end

      it 'queries for last N visits' do
        expect(BoardGroupRecentVisit).to receive(:latest).with(user, group, count: 5).once

        described_class.new(group_board.resource_parent, user).latest(5)
      end
    end
  end
end
