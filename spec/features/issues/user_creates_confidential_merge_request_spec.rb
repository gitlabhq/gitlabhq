# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates confidential merge request on issue page', :js, feature_category: :team_planning do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :public) }
  let(:issue) { create(:issue, project: project, confidential: true) }

  def visit_confidential_issue
    sign_in(user)
    visit project_issue_path(project, issue)
    wait_for_requests
  end

  before do
    project.add_developer(user)
  end

  context 'user has no private fork' do
    before do
      fork_project(project, user, repository: true)
      visit_confidential_issue
    end

    it 'shows that user has no fork available' do
      click_button 'Create confidential merge request'

      page.within '.create-confidential-merge-request-dropdown-menu' do
        expect(page).to have_content('No forks are available to you')
      end
    end
  end

  describe 'user has private fork' do
    let(:forked_project) { fork_project(project, user, repository: true) }

    before do
      forked_project.update!(visibility: Gitlab::VisibilityLevel::PRIVATE)
      visit_confidential_issue
    end

    it 'create merge request in fork', :sidekiq_might_not_need_inline do
      click_button 'Create confidential merge request'

      page.within '.create-confidential-merge-request-dropdown-menu' do
        expect(page).to have_button(forked_project.name_with_namespace)
        click_button 'Create confidential merge request'
      end

      expect(page).to have_content(forked_project.namespace.name)
    end
  end
end
