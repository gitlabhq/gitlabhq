# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Repository > Branch rules > Branch rule details', feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }

  let_it_be(:branch_rule) do
    create(
      :protected_branch,
      code_owner_approval_required: true,
      allow_force_push: false
    )
  end

  let_it_be(:project) { branch_rule.project }

  before do
    sign_in(user)
    stub_licensed_features(
      merge_request_approvers: true,
      external_status_checks: true
    )
  end

  context 'when viewed by developer' do
    before_all do
      project.add_developer(user)
    end

    it 'does not allow to view rule details' do
      visit_branch_rule_details

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when viewed by maintainer', :js do
    before_all do
      project.add_maintainer(user)
    end

    before do
      visit_branch_rule_details
      wait_for_requests
    end

    it 'renders rule details', :aggregate_failures do
      expect(page).to have_text 'Branch rule details'
      expect(page).to have_css '[data-testid="branch"]', text: branch_rule.name
      expect(page).to have_text 'Protect branch'
      expect(page).to have_text 'Allowed to push and merge'
      expect(page).to have_text 'Allowed to merge'
    end

    it 'displays the number of matching branches for wildcard patterns' do
      repo_project = create(:project, :repository)
      repo_project.add_maintainer(user)
      repo_project.repository.add_branch(user, 'production-stable', 'master')
      repo_project.repository.add_branch(user, 'staging-stable', 'master')
      wildcard_rule = create(:protected_branch, name: '*-stable', project: repo_project)

      visit project_settings_repository_branch_rules_path(repo_project, params: { branch: wildcard_rule.name })
      wait_for_requests

      expect(page).to have_text '2 matching branches'
    end

    it 'renders breadcrumbs', :aggregate_failures do
      within_testid 'breadcrumb-links' do
        expect(page).to have_link('Repository settings', href: project_settings_repository_path(project))
        expect(page).to have_link('Branch rules',
          href: project_settings_repository_path(project, anchor: 'branch-rules'))
        expect(page).to have_link('Details', href: '#')
      end
    end

    it 'changes target branch on edit' do
      within_testid('rule-target-card') do
        expect(page).to have_button('Edit', wait: 10)
        click_button 'Edit'
      end

      within_modal do
        expect(page).to have_text 'Update target branch'
        click_button 'Select branch or create rule'
        fill_in 'Search branches', with: 'test-*'
        find_by_testid('listbox-item-test-*').click
        click_button 'Update'
      end

      wait_for_requests
      visit_branch_rules_listing
      wait_for_requests

      expect(page).to have_css '[data-testid="branch-content"]', text: 'test-*'
    end

    it 'deletes a rule' do
      expect(page).to have_button('Delete', wait: 10)
      click_button 'Delete'

      within_modal do
        click_button 'Delete branch rule'
      end

      wait_for_requests
      visit_branch_rules_listing
      wait_for_requests

      expect(page).not_to have_css '[data-testid="branch-content"]', text: branch_rule.name
    end

    describe 'Access control - roles' do
      context 'for Allowed to merge' do
        it 'can edit access levels with different roles' do
          within_testid('allowed-to-merge-content') do
            click_button 'Edit'
          end

          within('.gl-drawer') do
            expect(page).to have_text 'Edit allowed to merge'
            check 'Developers and Maintainers'
            click_button 'Save changes'
          end

          wait_for_requests

          within_testid('allowed-to-merge-content') do
            expect(page).to have_text 'Developers and Maintainers'
          end
        end
      end

      context 'for Allowed to push and merge' do
        it 'can edit access levels with different roles' do
          within_testid('allowed-to-push-content') do
            click_button 'Edit'
          end

          within('.gl-drawer') do
            expect(page).to have_text 'Edit allowed to push and merge'
            check 'Developers and Maintainers'
            click_button 'Save changes'
          end

          wait_for_requests

          within_testid('allowed-to-push-content') do
            expect(page).to have_text 'Developers and Maintainers'
          end

          visit_branch_rule_details
          wait_for_requests

          within_testid('allowed-to-push-content') do
            expect(page).to have_text 'Developers and Maintainers'
          end
        end

        describe 'Deploy keys' do
          let_it_be(:deploy_key_with_write_access) { create(:deploy_key, user: user, write_access_to: project) }
          let_it_be(:deploy_key_readonly) { create(:deploy_key, user: user, readonly_access_to: project) }

          it 'does not show readonly deploy keys in push access drawer' do
            within_testid('allowed-to-push-content') do
              click_button 'Edit'
            end

            within('.gl-drawer') do
              expect(page).not_to have_text deploy_key_readonly.title
            end
          end

          it 'can select a deploy key for push access' do
            within_testid('allowed-to-push-content') do
              click_button 'Edit'
            end

            within('.gl-drawer') do
              within_testid('deploy-keys-selector') do
                first('.form-control').click
                find('.gl-new-dropdown-item', text: deploy_key_with_write_access.title).click
              end
              click_button 'Save changes'
            end

            wait_for_requests

            within_testid('allowed-to-push-content') do
              expect(page).to have_text deploy_key_with_write_access.title
            end
          end
        end
      end
    end

    describe 'Allow force push toggle' do
      it 'can toggle force push value' do
        within_testid('force-push-content') do
          find('button').click
        end

        wait_for_requests
        visit_branch_rule_details
        wait_for_requests

        within_testid('force-push-content') do
          toggle = find('button')
          expect(toggle[:class]).to include('is-checked')
        end
      end
    end

    describe 'Squash commits settings' do
      it 'renders squash commits section for non-wildcard branch without edit button' do
        within_testid('squash-setting-content') do
          expect(page).to have_text 'Squash commits when merging'
          expect(page).not_to have_button 'Edit'
        end
      end

      context 'with wildcard branch rule' do
        it 'does not render squash commits section' do
          repo_project = create(:project, :repository)
          repo_project.add_maintainer(user)
          wildcard_rule = create(:protected_branch, name: '*-stable', project: repo_project)

          visit project_settings_repository_branch_rules_path(repo_project, params: { branch: wildcard_rule.name })
          wait_for_requests

          expect(page).not_to have_css('[data-testid="squash-setting-content"]')
        end
      end

      context 'with All branches rule' do
        it 'renders squash commits section with edit button' do
          visit project_settings_repository_branch_rules_path(project, params: { branch: 'All branches' })
          wait_for_requests

          within_testid('squash-setting-content') do
            expect(page).to have_text 'Squash commits when merging'
            expect(page).to have_button 'Edit'
          end
        end
      end
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.skipping :'link-in-text-block'
    end
  end

  def visit_branch_rules_listing
    visit project_settings_repository_path(project)
  end

  def visit_branch_rule_details
    visit project_settings_repository_branch_rules_path(project, params: { branch: branch_rule.name })
  end
end
