# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues shortcut', :js, feature_category: :team_planning do
  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'New Issue shortcut' do
    context 'issues are enabled' do
      let(:project) { create(:project) }

      before do
        sign_in(project.first_owner)

        visit project_path(project)
      end

      it 'takes user to the new issue page' do
        send_keys('i')

        expect(page).to have_css('h1', text: 'New issue')
        expect(page).to have_current_path(new_project_issue_path(project))
      end
    end

    context 'issues are not enabled' do
      let(:project) { create(:project, :issues_disabled) }

      before do
        sign_in(project.first_owner)

        visit project_path(project)
      end

      it 'does not take user to the new issue page' do
        send_keys('i')

        expect(page).to have_selector("body[data-page='projects:show']")
        expect(page).not_to have_css('h1', text: 'New issue')
      end
    end
  end
end
