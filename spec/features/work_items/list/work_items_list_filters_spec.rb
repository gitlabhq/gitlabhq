# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work items list filters', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group, developers: [user1, user2]) }

  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }

  let_it_be(:milestone1) { create(:milestone, project: project, start_date: 5.days.ago, due_date: 13.days.from_now) }
  let_it_be(:milestone2) do
    create(:milestone, project: project, start_date: 2.days.from_now, due_date: 9.days.from_now)
  end

  let_it_be(:release1) { create(:release, project: project, tag: 'v1.0.0', milestones: [milestone1]) }
  let_it_be(:release2) { create(:release, project: project, tag: 'v2.0.0', milestones: [milestone2]) }

  let_it_be(:incident) do
    create(:incident, project: project,
      assignees: [user1],
      author: user1,
      description: 'aaa',
      labels: [label1])
  end

  let_it_be(:issue) do
    create(:issue, project: project,
      author: user1,
      labels: [label1, label2],
      milestone: milestone1,
      title: 'eee')
  end

  let_it_be(:task) do
    create(:work_item, :task, project: project,
      assignees: [user2],
      author: user2,
      confidential: true,
      milestone: milestone2)
  end

  let_it_be(:award_emoji) { create(:award_emoji, :upvote, user: user1, awardable: issue) }

  context 'for signed in user' do
    before do
      sign_in(user1)
      visit group_work_items_path(group)
    end

    describe 'assignee' do
      it 'filters', :aggregate_failures do
        select_tokens 'Assignee', '=', user1.username, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(incident.title)

        click_button 'Clear'

        select_tokens 'Assignee', '!=', user1.username, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(issue.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Assignee', '||', user1.username, 'Assignee', '||', user2.username, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Assignee', '=', 'None', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'Assignee', '=', 'Any', submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(task.title)
      end
    end

    describe 'author' do
      it 'filters', :aggregate_failures do
        select_tokens 'Author', '=', user1.username, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'Author', '!=', user1.username, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Author', '||', user1.username, 'Author', '||', user2.username, submit: true

        expect(page).to have_css('.issue', count: 3)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(issue.title)
        expect(page).to have_link(task.title)
      end
    end

    describe 'confidential' do
      it 'filters', :aggregate_failures do
        select_tokens 'Confidential', 'Yes', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Confidential', 'No', submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(issue.title)
      end
    end

    describe 'label' do
      it 'filters', :aggregate_failures do
        select_tokens 'Label', '=', label1.title, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'Label', '!=', label1.title, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Label', '||', label1.title, 'Label', '||', label2.title, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'Label', '=', 'None', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Label', '=', 'Any', submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(issue.title)
      end
    end

    describe 'milestone' do
      it 'filters', :aggregate_failures do
        select_tokens 'Milestone', '=', milestone1.title, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'Milestone', '!=', milestone1.title, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Milestone', '=', 'None', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(incident.title)

        click_button 'Clear'

        select_tokens 'Milestone', '=', 'Any', submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(issue.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Milestone', '=', 'Upcoming', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Milestone', '=', 'Started', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)
      end
    end

    describe 'my-reaction' do
      it 'filters', :aggregate_failures do
        select_tokens 'My reaction', '=', AwardEmoji::THUMBS_UP, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'My reaction', '!=', AwardEmoji::THUMBS_UP, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'My reaction', '=', 'None', submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'My reaction', '=', 'Any', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)
      end
    end

    describe 'search within' do
      it 'filters', :aggregate_failures do
        select_tokens 'Search within', 'Titles'
        send_keys 'eee', :enter, :enter

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'Search within', 'Descriptions'
        send_keys 'aaa', :enter, :enter

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(incident.title)
      end
    end

    describe 'release' do
      before do
        visit project_work_items_path(project)
      end

      it 'filters', :aggregate_failures do
        select_tokens 'Release', '=', 'v2.0.0', submit: true

        wait_for_requests
        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Release', '=', 'None', submit: true

        wait_for_requests
        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(incident.title)

        click_button 'Clear'

        select_tokens 'Release', '=', 'Any', submit: true

        wait_for_requests
        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(issue.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'Release', '!=', 'v1.0.0', submit: true

        wait_for_requests
        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)
      end
    end

    describe 'customer relations organization' do
      let_it_be(:crm_organization1) { create(:crm_organization, group: group, name: 'GitLab Inc') }
      let_it_be(:crm_organization2) { create(:crm_organization, group: group, name: 'Acme Corp') }

      # Create contacts belonging to organizations
      let_it_be(:contact1) { create(:contact, group: group, organization: crm_organization1) }
      let_it_be(:contact2) { create(:contact, group: group, organization: crm_organization1) }
      let_it_be(:contact3) { create(:contact, group: group, organization: crm_organization2) }

      # Create issues and relate them to contacts (which belong to organizations)
      let_it_be(:org1_issue1) { create(:issue, project: project, title: 'GitLab Issue 1') }
      let_it_be(:org1_issue2) { create(:issue, project: project, title: 'GitLab Issue 2') }
      let_it_be(:org2_issue) { create(:issue, project: project, title: 'Acme Issue') }

      # Create the relationships between issues and contacts
      let_it_be(:issue_contact1) { create(:issue_customer_relations_contact, issue: org1_issue1, contact: contact1) }
      let_it_be(:issue_contact2) { create(:issue_customer_relations_contact, issue: org1_issue2, contact: contact2) }
      let_it_be(:issue_contact3) { create(:issue_customer_relations_contact, issue: org2_issue, contact: contact3) }

      shared_examples 'filters by CRM organization' do
        it 'filters by CRM organization', :aggregate_failures do
          # Organization just supports is operator so no need for passing '='
          select_tokens 'Organization', crm_organization1.name, submit: true

          expect(page).to have_css('.issue', count: 2)
          expect(page).to have_link(org1_issue1.title)
          expect(page).to have_link(org1_issue2.title)

          click_button 'Clear'

          select_tokens 'Organization', crm_organization2.name, submit: true

          expect(page).to have_css('.issue', count: 1)
          expect(page).to have_link(org2_issue.title)
        end
      end

      shared_examples 'filters by CRM contacts' do
        it 'filters by CRM contacts', :aggregate_failures do
          # Contact just supports `is` operator so no need for passing '='
          select_tokens 'Contact', contact1.first_name, submit: true

          expect(page).to have_css('.issue', count: 1)
          expect(page).to have_link(org1_issue1.title)

          click_button 'Clear'

          select_tokens 'Contact', contact2.first_name, submit: true

          expect(page).to have_css('.issue', count: 1)
          expect(page).to have_link(org1_issue2.title)
        end
      end

      before_all do
        group.add_developer(user1)
      end

      before do
        allow(user1).to receive_messages(read_crm_contact: true, read_crm_organization: true)

        sign_in(user1)
      end

      context 'when user is on group work items page' do
        before do
          visit group_work_items_path(group)
        end

        include_examples 'filters by CRM organization'
        include_examples 'filters by CRM contacts'
      end

      context 'when user is on work items page' do
        before do
          visit project_work_items_path(project)
        end

        include_examples 'filters by CRM organization'
        include_examples 'filters by CRM contacts'
      end

      context 'when user is on project issues page' do
        before do
          stub_feature_flags(work_item_planning_view: false)
          visit project_issues_path(project)
        end

        include_examples 'filters by CRM organization'
        include_examples 'filters by CRM contacts'
      end
    end
  end
end
