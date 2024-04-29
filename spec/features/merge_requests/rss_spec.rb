# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Merge Requests RSS', feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, developers: user) }
  let_it_be(:project) { create(:project, :repository, group: group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, assignees: [user]) }
  let_it_be(:path) { project_merge_requests_path(project) }

  context 'when signed in', :js do
    let_it_be(:user) { create(:user) }

    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
      visit path
      click_button 'Actions', match: :first
    end

    it_behaves_like "it has an RSS link with current_user's feed token"
    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
  end

  context 'when signed out', :js do
    before do
      visit path
      click_button 'Actions', match: :first
    end

    it_behaves_like "it has an RSS link without a feed token"
    it_behaves_like "an autodiscoverable RSS feed without a feed token"
  end

  describe 'feeds' do
    it_behaves_like 'updates atom feed link', :project do
      let(:path) { project_merge_requests_path(project, assignee_id: user.id) }
    end
  end
end
