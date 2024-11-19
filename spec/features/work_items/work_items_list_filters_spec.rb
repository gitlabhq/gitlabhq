# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work items list filters', :js, feature_category: :team_planning do
  include WorkItemFeedbackHelpers
  include FilteredSearchHelpers

  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, :public, group: group, developers: [user1, user2]) }
  let_it_be(:sub_group_project) { create(:project, :public, group: sub_group, developers: [user1, user2]) }

  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }

  let_it_be(:milestone1) { create(:milestone, group: group, start_date: 5.days.ago, due_date: 13.days.from_now) }
  let_it_be(:milestone2) { create(:milestone, group: group, start_date: 2.days.from_now, due_date: 9.days.from_now) }

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
    create(:work_item, :task, project: sub_group_project,
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

      close_work_item_feedback_popover_if_present
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

    describe 'group' do
      it 'filters', :aggregate_failures do
        select_tokens 'Group', sub_group.name, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(task.title)
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
        select_tokens 'My-Reaction', '=', AwardEmoji::THUMBS_UP, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'My-Reaction', '!=', AwardEmoji::THUMBS_UP, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'My-Reaction', '=', 'None', submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(incident.title)
        expect(page).to have_link(task.title)

        click_button 'Clear'

        select_tokens 'My-Reaction', '=', 'Any', submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)
      end
    end

    describe 'search within' do
      it 'filters', :aggregate_failures do
        select_tokens 'Search Within', 'Titles'
        send_keys 'eee', :enter, :enter

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(issue.title)

        click_button 'Clear'

        select_tokens 'Search Within', 'Descriptions'
        send_keys 'aaa', :enter, :enter

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(incident.title)
      end
    end
  end
end
