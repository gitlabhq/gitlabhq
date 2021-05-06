# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group milestones' do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project_empty_repo, group: group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }

  around do |example|
    freeze_time { example.run }
  end

  before do
    sign_in(user)
  end

  context 'create a milestone', :js do
    before do
      visit new_group_milestone_path(group)
    end

    it 'renders description preview' do
      description = find('.note-textarea')

      description.native.send_keys('')

      click_button('Preview')

      preview = find('.js-md-preview')

      expect(preview).to have_content('Nothing to preview.')

      click_button('Write')

      description.native.send_keys(':+1: Nice')

      click_button('Preview')

      expect(preview).to have_css('gl-emoji')
      expect(find('#milestone_description', visible: false)).not_to be_visible
    end

    it 'creates milestone with start date' do
      fill_in 'Title', with: 'testing'
      find('#milestone_start_date').click

      page.within(find('.pika-single')) do
        click_button '1'
      end

      click_button 'Create milestone'

      expect(find('.start_date')).to have_content(Date.today.at_beginning_of_month.strftime('%b %-d, %Y'))
    end

    it 'description input support autocomplete' do
      description = find('.note-textarea')
      description.native.send_keys('!')

      expect(page).to have_selector('.atwho-view')
    end
  end

  context 'milestones list' do
    context 'when no milestones' do
      it 'renders no milestones text' do
        visit group_milestones_path(group)
        expect(page).to have_content('No milestones to show')
      end
    end

    context 'when milestones exists' do
      let_it_be(:other_project) { create(:project_empty_repo, group: group) }

      let_it_be(:active_project_milestone1) do
        create(
          :milestone,
          project: project,
          state: 'active',
          title: 'v1.0',
          due_date: '2114-08-20',
          description: 'Lorem Ipsum is simply dummy text'
        )
      end

      let_it_be(:active_project_milestone2) { create(:milestone, project: other_project, state: 'active', title: 'v1.1') }
      let_it_be(:closed_project_milestone1) { create(:milestone, project: project, state: 'closed', title: 'v2.0') }
      let_it_be(:closed_project_milestone2) { create(:milestone, project: other_project, state: 'closed', title: 'v2.0') }
      let_it_be(:active_group_milestone) { create(:milestone, group: group, state: 'active', title: 'GL-113') }
      let_it_be(:closed_group_milestone) { create(:milestone, group: group, state: 'closed') }
      let_it_be(:issue) do
        create :issue, project: project, assignees: [user], author: user, milestone: active_project_milestone1
      end

      before do
        visit group_milestones_path(group)
      end

      it 'counts milestones correctly' do
        expect(find('.top-area .active .badge').text).to eq("3")
        expect(find('.top-area .closed .badge').text).to eq("3")
        expect(find('.top-area .all .badge').text).to eq("6")
      end

      it 'lists group and project milestones' do
        expect(page).to have_selector("#milestone_#{active_group_milestone.id}", count: 1)
        expect(page).to have_selector("#milestone_#{active_project_milestone2.id}", count: 1)
      end

      it 'shows milestone detail and supports its edit' do
        page.within(".milestones #milestone_#{active_group_milestone.id}") do
          click_link(active_group_milestone.title)
        end

        page.within('.detail-page-header') do
          click_link('Edit')
        end

        expect(page).to have_selector('.milestone-form')
      end

      it 'renders milestones' do
        expect(page).to have_content('v1.0')
        expect(page).to have_content('v1.1')
        expect(page).to have_content('GL-113')
        expect(page).to have_link(
          'v1.0',
          href: project_milestone_path(project, active_project_milestone1)
        )
        expect(page).to have_link(
          '1 Issue',
          href: project_issues_path(project, milestone_title: 'v1.0')
        )
        expect(page).to have_link(
          '0 Merge requests',
          href: project_merge_requests_path(project, milestone_title: 'v1.0')
        )
        expect(page).to have_link(
          'GL-113',
          href: group_milestone_path(group, active_group_milestone)
        )
        expect(page).to have_link(
          '0 Issues',
          href: issues_group_path(group, milestone_title: 'GL-113')
        )
        expect(page).to have_link(
          '0 Merge requests',
          href: merge_requests_group_path(group, milestone_title: 'GL-113')
        )
      end
    end
  end

  describe 'milestone tabs', :js do
    context 'for a group milestone' do
      let_it_be(:other_project) { create(:project_empty_repo, group: group) }
      let_it_be(:milestone) { create(:milestone, group: group) }

      let_it_be(:project_label) { create(:label, project: project) }
      let_it_be(:other_project_label) { create(:label, project: other_project) }

      let_it_be(:project_issue) { create(:labeled_issue, project: project, milestone: milestone, labels: [project_label], assignees: [create(:user)]) }
      let_it_be(:other_project_issue) { create(:labeled_issue, project: other_project, milestone: milestone, labels: [other_project_label], assignees: [create(:user)]) }

      let_it_be(:project_mr) { create(:merge_request, source_project: project, milestone: milestone) }
      let_it_be(:other_project_mr) { create(:merge_request, source_project: other_project, milestone: milestone) }

      before do
        visit group_milestone_path(group, milestone)
      end

      it 'renders the issues tab' do
        within('#tab-issues') do
          expect(page).to have_content project_issue.title
          expect(page).to have_content other_project_issue.title
        end
      end

      it 'renders the merge requests tab' do
        within('.js-milestone-tabs') do
          click_link('Merge requests')
        end

        within('#tab-merge-requests') do
          expect(page).to have_content project_mr.title
          expect(page).to have_content other_project_mr.title
        end
      end

      it 'renders the participants tab' do
        within('.js-milestone-tabs') do
          click_link('Participants')
        end

        within('#tab-participants') do
          expect(page).to have_content project_issue.assignees.first.name
          expect(page).to have_content other_project_issue.assignees.first.name
        end
      end

      it 'renders the labels tab' do
        within('.js-milestone-tabs') do
          click_link('Labels')
        end

        within('#tab-labels') do
          expect(page).to have_content project_label.title
          expect(page).to have_content other_project_label.title
        end
      end
    end
  end
end
