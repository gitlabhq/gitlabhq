# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues shortcut', :js, feature_category: :team_planning do
  context 'New Issue shortcut' do
    context 'issues are enabled' do
      let(:project) { create(:project) }

      before do
        sign_in(project.first_owner)

        visit project_path(project)
      end

      it 'takes user to the new issue page' do
        find('body').native.send_keys('i')
        expect(page).to have_selector('#new_issue')
      end
    end

    context 'issues are not enabled' do
      let(:project) { create(:project, :issues_disabled) }

      before do
        sign_in(project.first_owner)

        visit project_path(project)
      end

      it 'does not take user to the new issue page' do
        find('body').native.send_keys('i')

        expect(page).to have_selector("body[data-page='projects:show']")
      end
    end
  end
end
