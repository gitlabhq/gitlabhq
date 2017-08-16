require 'spec_helper'

feature 'Group issues page' do
  include FilteredSearchHelpers

  let(:path) { issues_group_path(group) }
  let(:issuable) { create(:issue, project: project, title: "this is my created issuable")}

  include_examples 'project features apply to issuables', Issue

  context 'rss feed' do
    let(:access_level) { ProjectFeature::ENABLED }

    context 'when signed in' do
      let(:user) { user_in_group }

      it_behaves_like "it has an RSS button with current_user's RSS token"
      it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token"
    end

    context 'when signed out' do
      let(:user) { nil }

      it_behaves_like "it has an RSS button without an RSS token"
      it_behaves_like "an autodiscoverable RSS feed without an RSS token"
    end
  end

  context 'assignee', :js do
    let(:access_level) { ProjectFeature::ENABLED }
    let(:user) { user_in_group }
    let(:user2) { user_outside_group }
    let(:path) { issues_group_path(group) }

    it 'filters by only group users' do
      filtered_search.set('assignee:')

      expect(find('#js-dropdown-assignee .filter-dropdown')).to have_content(user.name)
      expect(find('#js-dropdown-assignee .filter-dropdown')).not_to have_content(user2.name)
    end
  end
end
