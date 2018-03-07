require 'rails_helper'

feature 'Group milestones' do
  let(:group) { create(:group) }
  let!(:project) { create(:project_empty_repo, group: group) }
  let(:user) { create(:group_member, :master, user: create(:user), group: group ).user }

  around do |example|
    Timecop.freeze { example.run }
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

      click_link('Preview')

      preview = find('.js-md-preview')

      expect(preview).to have_content('Nothing to preview.')

      click_link('Write')

      description.native.send_keys(':+1: Nice')

      click_link('Preview')

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

    it 'description input does not support autocomplete' do
      description = find('.note-textarea')
      description.native.send_keys('!')

      expect(page).not_to have_selector('.atwho-view')
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
      let!(:other_project) { create(:project_empty_repo, group: group) }

      let!(:active_project_milestone1) do
        create(
          :milestone,
          project: project,
          state: 'active',
          title: 'v1.0',
          due_date: '2114-08-20',
          description: 'Lorem Ipsum is simply dummy text'
        )
      end
      let!(:active_project_milestone2) { create(:milestone, project: other_project, state: 'active', title: 'v1.0') }
      let!(:closed_project_milestone1) { create(:milestone, project: project, state: 'closed', title: 'v2.0') }
      let!(:closed_project_milestone2) { create(:milestone, project: other_project, state: 'closed', title: 'v2.0') }
      let!(:active_group_milestone) { create(:milestone, group: group, state: 'active', title: 'GL-113') }
      let!(:closed_group_milestone) { create(:milestone, group: group, state: 'closed') }
      let!(:issue) do
        create :issue, project: project, assignees: [user], author: user, milestone: active_project_milestone1
      end

      before do
        visit group_milestones_path(group)
      end

      it 'counts milestones correctly' do
        expect(find('.top-area .active .badge').text).to eq("2")
        expect(find('.top-area .closed .badge').text).to eq("2")
        expect(find('.top-area .all .badge').text).to eq("4")
      end

      it 'lists legacy group milestones and group milestones' do
        legacy_milestone = GroupMilestone.build_collection(group, group.projects, { state: 'active' }).first

        expect(page).to have_selector("#milestone_#{active_group_milestone.id}", count: 1)
        expect(page).to have_selector("#milestone_#{legacy_milestone.milestones.first.id}", count: 1)
      end

      it 'updates milestone' do
        page.within(".milestones #milestone_#{active_group_milestone.id}") do
          click_link('Edit')
        end

        page.within('.milestone-form') do
          fill_in 'milestone_title', with: 'new title'
          click_button('Update milestone')
        end

        expect(find('#content-body h2')).to have_content('new title')
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
        expect(page).to have_content('GL-113')
        expect(page).to have_link(
          '1 Issue',
          href: issues_group_path(group, milestone_title: 'v1.0')
        )
        expect(page).to have_link(
          '0 Merge Requests',
          href: merge_requests_group_path(group, milestone_title: 'v1.0')
        )
      end

      it 'renders group milestone details' do
        click_link 'v1.0'

        expect(page).to have_content('expires on Aug 20, 2114')
        expect(page).to have_content('v1.0')
        expect(page).to have_content('Issues 1 Open: 1 Closed: 0')
        expect(page).to have_link(issue.title, href: project_issue_path(issue.project, issue))
      end

      describe 'labels' do
        before do
          create(:label, project: project, title: 'bug') do |label|
            issue.labels << label
          end

          create(:label, project: project, title: 'feature') do |label|
            issue.labels << label
          end
        end

        it 'renders labels' do
          click_link 'v1.0'

          page.within('#tab-issues') do
            expect(page).to have_content 'bug'
            expect(page).to have_content 'feature'
          end
        end

        it 'renders labels list', :js do
          click_link 'v1.0'

          page.within('.content .nav-links') do
            page.find(:xpath, "//a[@href='#tab-labels']").click
          end

          page.within('#tab-labels') do
            expect(page).to have_content 'bug'
            expect(page).to have_content 'feature'
          end
        end
      end
    end
  end
end
