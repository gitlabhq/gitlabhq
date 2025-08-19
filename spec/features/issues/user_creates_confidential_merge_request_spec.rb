# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates confidential merge request on issue page', :js, feature_category: :team_planning do
  include ProjectForksHelper
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :public) }
  let(:issue) { create(:issue, project: project, confidential: true) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    project.add_developer(user)
  end

  context 'user has no private fork' do
    before do
      fork_project(project, user, repository: true)
      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'shows that user has no fork available' do
      click_button 'Create merge request'

      within_modal do
        expect(page).to have_content('No forks are available to you')
        expect(page).to have_button('Create merge request', disabled: true)
      end
    end
  end

  describe 'user has private fork' do
    let(:forked_project) { fork_project(project, user, repository: true) }

    before do
      forked_project.update!(visibility: Gitlab::VisibilityLevel::PRIVATE)
      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'create merge request in fork', :sidekiq_might_not_need_inline do
      click_button 'Create merge request'

      within_modal do
        expect(page).to have_button(forked_project.full_path)

        click_button 'Create merge request'
      end

      expect(page).to have_css('h1', text: 'New merge request')
      expect(page).to have_text(forked_project.namespace.name)
    end
  end
end
