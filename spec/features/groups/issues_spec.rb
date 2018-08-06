require 'spec_helper'

describe 'Group issues page' do
  include FilteredSearchHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group)}
  let(:project_with_issues_disabled) { create(:project, :issues_disabled, group: group) }
  let(:path) { issues_group_path(group) }

  context 'with shared examples' do
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

        it_behaves_like "it has an RSS button with current_user's feed token"
        it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
      end

      context 'when signed out' do
        let(:user) { nil }

        it_behaves_like "it has an RSS button without a feed token"
        it_behaves_like "an autodiscoverable RSS feed without a feed token"
      end
    end

    context 'assignee', :js do
      let(:access_level) { ProjectFeature::ENABLED }
      let(:user) { user_in_group }
      let(:user2) { user_outside_group }

      it 'filters by only group users' do
        filtered_search.set('assignee:')

        expect(find('#js-dropdown-assignee .filter-dropdown')).to have_content(user.name)
        expect(find('#js-dropdown-assignee .filter-dropdown')).not_to have_content(user2.name)
      end
    end
  end

  context 'issues list', :nested_groups do
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
        find('.new-project-item-link').click

        page.within('.select2-results') do
          expect(page).to have_content(project.full_name)
          expect(page).not_to have_content(project_with_issues_disabled.full_name)
        end
      end
    end
  end
end
