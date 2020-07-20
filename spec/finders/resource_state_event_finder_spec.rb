# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceStateEventFinder do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    subject { described_class.new(user, issue).execute }

    let(:project) { create(:project) }
    let(:issue) { create(:issue, project: project) }

    let!(:event) { create(:resource_state_event, issue: issue) }

    it 'returns events accessible by user' do
      project.add_guest(user)

      expect(subject).to eq [event]
    end

    context 'when issues are private' do
      let(:project) { create(:project, :public, :issues_private) }

      it 'does not return any events' do
        expect(subject).to be_empty
      end
    end

    context 'when issue is not accesible to the user' do
      let(:project) { create(:project, :private) }

      it 'does not return any events' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#can_read_eventable?' do
    let(:project) { create(:project, :private) }

    subject { described_class.new(user, eventable).can_read_eventable? }

    context 'when eventable is an Issue' do
      let(:eventable) { create(:issue, project: project) }

      context 'when issue is readable' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when issue is not readable' do
        it { is_expected.to be_falsey }
      end
    end

    context 'when eventable is a MergeRequest' do
      let(:eventable) { create(:merge_request, source_project: project) }

      context 'when merge request is readable' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when merge request is not readable' do
        it { is_expected.to be_falsey }
      end
    end
  end
end
