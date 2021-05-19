# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group issues page' do
  include FilteredSearchHelpers
  include DragTo

  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group)}
  let(:project_with_issues_disabled) { create(:project, :issues_disabled, group: group) }
  let(:path) { issues_group_path(group) }

  context 'with shared examples', :js do
    let(:issuable) { create(:issue, project: project, title: "this is my created issuable")}

    include_examples 'project features apply to issuables', Issue

    context 'rss feed' do
      let(:access_level) { ProjectFeature::ENABLED }

      context 'when signed in' do
        let(:user) do
          user_in_group.ensure_feed_token
          user_in_group.save!
          user_in_group
        end

        it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"

        # Note: The one from rss_shared_example.rb uses a css pseudo-class `:has`
        # which is VERY experimental and only supported in Nokogiri used by Capybara
        # However,`:js` option forces Capybara to use Selenium that doesn't support`:has`
        context "it has an RSS button with current_user's feed token" do
          it "shows the RSS button with current_user's feed token" do
            expect(find('[data-testid="rss-feed-link"]')['href']).to have_content(user.feed_token)
          end
        end
      end

      context 'when signed out' do
        let(:user) { nil }

        it_behaves_like "an autodiscoverable RSS feed without a feed token"

        # Note: please see the above
        context "it has an RSS button without a feed token" do
          it "shows the RSS button without a feed token" do
            expect(find('[data-testid="rss-feed-link"]')['href']).not_to have_content('feed_token')
          end
        end
      end
    end

    context 'assignee' do
      let(:access_level) { ProjectFeature::ENABLED }
      let(:user) { user_in_group }
      let(:user2) { user_outside_group }

      it 'filters by only group users' do
        filtered_search.set('assignee:=')

        expect(find('#js-dropdown-assignee .filter-dropdown')).to have_content(user.name)
        expect(find('#js-dropdown-assignee .filter-dropdown')).not_to have_content(user2.name)
      end
    end
  end

  context 'issues list', :js do
    let(:subgroup) { create(:group, parent: group) }
    let(:subgroup_project) { create(:project, :public, group: subgroup)}
    let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group ).user }
    let!(:issue) { create(:issue, project: project, title: 'root group issue') }
    let!(:subgroup_issue) { create(:issue, project: subgroup_project, title: 'subgroup issue') }

    it 'returns all group and subgroup issues' do
      visit issues_group_path(group)

      page.within('.issuable-list') do
        expect(page).to have_selector('li.issue', count: 2)
        expect(page).to have_content('root group issue')
        expect(page).to have_content('subgroup issue')
      end
    end

    context 'when project is archived' do
      before do
        ::Projects::UpdateService.new(project, user_in_group, archived: true).execute
      end

      it 'does not render issue' do
        visit path

        expect(page).not_to have_content issue.title[0..80]
      end
    end
  end

  context 'projects with issues disabled' do
    describe 'issue dropdown' do
      let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group ).user }

      before do
        [project, project_with_issues_disabled].each { |project| project.add_maintainer(user_in_group) }
        sign_in(user_in_group)
        visit issues_group_path(group)
      end

      it 'shows projects only with issues feature enabled', :js do
        find('.empty-state .js-lazy-loaded')
        find('.empty-state .new-project-item-link').click

        page.within('.select2-results') do
          expect(page).to have_content(project.full_name)
          expect(page).not_to have_content(project_with_issues_disabled.full_name)
        end
      end
    end
  end

  context 'manual ordering', :js do
    let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group ).user }

    let!(:issue1) { create(:issue, project: project, title: 'Issue #1', relative_position: 1) }
    let!(:issue2) { create(:issue, project: project, title: 'Issue #2', relative_position: 2) }
    let!(:issue3) { create(:issue, project: project, title: 'Issue #3', relative_position: 3) }

    before do
      sign_in(user_in_group)
    end

    it 'displays all issues' do
      visit issues_group_path(group, sort: 'relative_position')

      page.within('.issues-list') do
        expect(page).to have_selector('li.issue', count: 3)
      end
    end

    it 'has manual-ordering css applied' do
      visit issues_group_path(group, sort: 'relative_position')

      expect(page).to have_selector('.manual-ordering')
    end

    it 'each issue item has a user-can-drag css applied' do
      visit issues_group_path(group, sort: 'relative_position')

      page.within('.manual-ordering') do
        expect(page).to have_selector('.issue.user-can-drag', count: 3)
      end
    end

    it 'issues should be draggable and persist order' do
      visit issues_group_path(group, sort: 'relative_position')

      wait_for_requests

      drag_to(selector: '.manual-ordering',
        from_index: 0,
        to_index: 2)

      wait_for_requests

      check_issue_order

      visit issues_group_path(group, sort: 'relative_position')

      check_issue_order
    end

    it 'issues should not be draggable when user is not logged in' do
      sign_out(user_in_group)

      visit issues_group_path(group, sort: 'relative_position')

      wait_for_requests

      drag_to(selector: '.manual-ordering',
        from_index: 0,
        to_index: 2)

      wait_for_requests

      # Issue order should remain the same
      page.within('.manual-ordering') do
        expect(find('.issue:nth-child(1) .title')).to have_content('Issue #1')
        expect(find('.issue:nth-child(2) .title')).to have_content('Issue #2')
        expect(find('.issue:nth-child(3) .title')).to have_content('Issue #3')
      end
    end

    def check_issue_order
      page.within('.manual-ordering') do
        expect(find('.issue:nth-child(1) .title')).to have_content('Issue #2')
        expect(find('.issue:nth-child(2) .title')).to have_content('Issue #3')
        expect(find('.issue:nth-child(3) .title')).to have_content('Issue #1')
      end
    end
  end

  context 'issues pagination', :js do
    let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group ).user }

    let!(:issues) do
      (1..25).to_a.map { |index| create(:issue, project: project, title: "Issue #{index}") }
    end

    before do
      sign_in(user_in_group)
      visit issues_group_path(group)
    end

    it 'shows the pagination' do
      expect(page).to have_selector('.gl-pagination')
    end

    it 'first pagination item is active' do
      page.within('.gl-pagination') do
        expect(find('li.active')).to have_content('1')
      end
    end
  end
end
