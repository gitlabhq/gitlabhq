# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Repository > Branch rules settings', feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers
  let(:user) { create(:user) }
  let(:role) { :developer }

  let(:branch_rule) do
    create(
      :protected_branch,
      code_owner_approval_required: true,
      allow_force_push: false
    )
  end

  let(:project) { branch_rule.project }
  let(:external_status_check) do
    create(:external_status_check, project: project, protected_branches: [branch_rule])
  end

  before do
    project.add_role(user, role)
    sign_in(user)
    stub_licensed_features(
      merge_request_approvers: true,
      external_status_checks: true
    )
  end

  context 'When viewed by developer' do
    let(:role) { :developer }

    it 'does not allow to view rule details' do
      visit_branch_rules_details

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'When viewed by maintainer' do
    let(:role) { :maintainer }

    it 'allows to view rule details' do
      visit_branch_rules_details

      expect(page).to have_gitlab_http_status(:ok)
    end
  end

  context 'Branch rule details for custom rule', :js do
    let(:role) { :maintainer }

    before do
      visit_branch_rules_details
      wait_for_requests
    end

    it 'renders rule details' do
      expect(page).to have_css 'h1', text: 'Branch rule details'
      expect(page).to have_css '[data-testid="branch"]', text: branch_rule.name
      expect(page).to have_css 'h2', text: 'Protect branch'
      expect(page).to have_text 'Allowed to push and merge'
      expect(page).to have_text 'Allowed to merge'
    end

    it 'renders breadcrumbs' do
      within_testid 'breadcrumb-links' do
        expect(page).to have_link('Repository Settings', href: project_settings_repository_path(project))
        expect(page).to have_link('Branch rules',
          href: project_settings_repository_path(project, anchor: 'branch-rules'))
        expect(page).to have_link('Details', href: '#')
      end
    end

    it 'changes target branch on edit' do
      within_testid('rule-target-card') do
        click_button 'Edit'
      end

      within_modal do
        expect(page).to have_text 'Update target branch'
        click_button 'Select Branch or create wildcard'
        fill_in 'Search', with: 'test-*'
        find_by_testid('listbox-item-test-*').click
        click_button 'Update'
      end

      wait_for_requests

      visit_branch_rules_settings
      wait_for_requests

      expect(page).to have_css '[data-testid="branch-content"]', text: 'test-*'
    end

    it 'deletes rule' do
      click_button 'Delete'

      within_modal do
        click_button 'Delete branch rule'
      end

      wait_for_requests

      visit_branch_rules_settings
      wait_for_requests

      expect(page).not_to have_css '[data-testid="branch-content"]', text: branch_rule.name
    end

    it 'passes axe automated accessibility testing' do
      # checking the page for a custom rule to show all possible components
      expect(page).to be_axe_clean.skipping :'link-in-text-block'
    end
  end

  def visit_branch_rules_settings
    visit project_settings_repository_path(project)
  end

  def visit_branch_rules_details
    visit project_settings_repository_branch_rules_path(project, params: { branch: branch_rule.name })
  end
end
