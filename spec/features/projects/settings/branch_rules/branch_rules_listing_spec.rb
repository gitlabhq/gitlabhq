# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Repository > Branch rules > Branch rules listing', :js,
  feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
    stub_licensed_features(
      merge_request_approvers: true,
      external_status_checks: true
    )
  end

  describe 'creating a branch rule with wildcard pattern' do
    it 'allows creating a branch rule with a wildcard', :aggregate_failures do
      visit project_settings_repository_path(project)
      wait_for_requests

      click_button 'Add branch rule'
      wait_for_requests

      expect(page).to have_text 'Add branch rule'
      click_button 'Branch name or pattern'
      click_button 'Select branch or create rule'
      fill_in 'Search branches', with: '*-stable'
      find_by_testid('listbox-item-*-stable').click
      click_button 'Create branch rule'

      wait_for_requests

      within_testid('rule-target-card') do
        expect(page).to have_content('*-stable')
      end
      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.name).to eq('*-stable')
    end
  end

  describe 'viewing existing branch rules' do
    let_it_be(:branch_rule, freeze: true) do
      create(
        :protected_branch,
        name: 'main',
        project: project
      )
    end

    it 'displays existing branch rules' do
      visit project_settings_repository_path(project)
      wait_for_requests

      expect(page).to have_css('[data-testid="branch-content"]', text: 'main')
    end
  end
end
