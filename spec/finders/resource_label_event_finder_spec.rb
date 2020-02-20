# frozen_string_literal: true

require 'spec_helper'

describe ResourceLabelEventFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:issue_project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: issue_project) }

  describe '#execute' do
    subject { described_class.new(user, issue).execute }

    it 'returns events with labels accessible by user' do
      label = create(:label, project: issue_project)
      event = create_event(label)
      issue_project.add_guest(user)

      expect(subject).to eq [event]
    end

    it 'filters events with public project labels if issues and MRs are private' do
      project = create(:project, :public, :issues_private, :merge_requests_private)
      label = create(:label, project: project)
      create_event(label)

      expect(subject).to be_empty
    end

    it 'filters events with project labels not accessible by user' do
      project = create(:project, :private)
      label = create(:label, project: project)
      create_event(label)

      expect(subject).to be_empty
    end

    it 'filters events with group labels not accessible by user' do
      group = create(:group, :private)
      label = create(:group_label, group: group)
      create_event(label)

      expect(subject).to be_empty
    end

    it 'paginates results' do
      label = create(:label, project: issue_project)
      create_event(label)
      create_event(label)
      issue_project.add_guest(user)

      paginated = described_class.new(user, issue, per_page: 1).execute

      expect(subject.count).to eq 2
      expect(paginated.count).to eq 1
    end

    def create_event(label)
      create(:resource_label_event, issue: issue, label: label)
    end
  end
end
