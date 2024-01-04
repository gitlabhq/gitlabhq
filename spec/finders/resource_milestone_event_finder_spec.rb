# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceMilestoneEventFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:issue_project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: issue_project) }

  describe '#execute' do
    subject { described_class.new(user, issue).execute }

    it 'returns events with milestones accessible by user' do
      milestone = create(:milestone, project: issue_project)
      event = create_event(milestone)
      issue_project.add_guest(user)

      expect(subject).to eq [event]
    end

    it 'filters events with public project milestones if issues and MRs are private' do
      project = create(:project, :public, :issues_private, :merge_requests_private)
      milestone = create(:milestone, project: project)
      create_event(milestone)

      expect(subject).to be_empty
    end

    it 'filters events with project milestones not accessible by user' do
      project = create(:project, :private)
      milestone = create(:milestone, project: project)
      create_event(milestone)

      expect(subject).to be_empty
    end

    it 'filters events with group milestones not accessible by user' do
      group = create(:group, :private)
      milestone = create(:milestone, group: group)
      create_event(milestone)

      expect(subject).to be_empty
    end

    context 'when multiple events share the same milestone' do
      it 'avoids N+1 queries' do
        issue_project.add_developer(user)

        milestone1 = create(:milestone, project: issue_project)
        milestone2 = create(:milestone, project: issue_project)

        control = ActiveRecord::QueryRecorder.new { described_class.new(user, issue).execute }
        expect(control.count).to eq(1) # 1 events query

        create_event(milestone1, :add)
        create_event(milestone1, :remove)
        create_event(milestone1, :add)
        create_event(milestone1, :remove)
        create_event(milestone2, :add)
        create_event(milestone2, :remove)

        # 1 milestones + 1 project + 1 user + 4 ability
        expect { described_class.new(user, issue).execute }.not_to exceed_query_limit(control).with_threshold(6)
      end
    end

    def create_event(milestone, action = :add)
      create(:resource_milestone_event, issue: issue, milestone: milestone, action: action)
    end
  end
end
