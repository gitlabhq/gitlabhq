# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform', :js, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:terraform_state) { create(:terraform_state, :locked, :with_version, project: project) }

  context 'when user is a terraform administrator' do
    let(:admin) { project.creator }

    before do
      gitlab_sign_in(admin)
    end

    context 'when user does not have any terraform states and visits the index page' do
      let(:empty_project) { create(:project) }

      before do
        empty_project.add_maintainer(admin)
        visit project_terraform_index_path(empty_project)
      end

      it 'sees an empty state' do
        expect(page).to have_content("Your project doesn't have any Terraform state files")
      end
    end

    context 'when user has a terraform state' do
      context 'when user visits the index page' do
        before do
          visit project_terraform_index_path(project)
        end

        it 'displays a tab with states count' do
          expect(page).to have_content("Terraform states #{project.terraform_states.size}")
        end

        it 'displays a table with terraform states' do
          expect(page).to have_selector(
            "[data-testid='terraform-states-table-name']",
            count: project.terraform_states.size
          )
        end

        it 'displays terraform actions dropdown' do
          expect(page).to have_selector(
            '[data-testid*="terraform-state-actions"]',
            count: project.terraform_states.size
          )
        end

        it 'displays terraform information' do
          expect(page).to have_content(terraform_state.name)
        end
      end

      context 'when clicking on the delete button' do
        let!(:additional_state) { create(:terraform_state, project: project) }

        it 'removes the state', :aggregate_failures do
          visit project_terraform_index_path(project)

          expect(page).to have_content(additional_state.name)

          find_by_testid("terraform-state-actions-#{additional_state.name}").click
          find_by_testid('terraform-state-remove').click
          fill_in "terraform-state-remove-input-#{additional_state.name}", with: additional_state.name
          click_button 'Remove'

          expect(page).to have_content("#{additional_state.name} successfully removed")

          find_by_testid('remove-icon').hover
          expect(page).to have_content("Deletion in progress")

          additional_state.reload
          expect(additional_state.deleted_at).not_to be_nil
        end
      end

      context 'when clicking on copy Terraform init command' do
        it 'shows the modal with the init command' do
          visit project_terraform_index_path(project)

          expect(page).to have_content(terraform_state.name)

          within_testid("terraform-state-actions-#{terraform_state.name}") do
            click_button class: 'gl-dropdown-toggle'
            click_button 'Copy Terraform init command'
          end

          expect(page).to have_content("To get access to this terraform state from your local computer, run the following command at the command line.")
        end
      end
    end
  end

  context 'when user is a terraform developer' do
    let_it_be(:developer) { create(:user) }

    before do
      project.add_developer(developer)
      gitlab_sign_in(developer)
      visit project_terraform_index_path(project)
    end

    context 'when user visits the index page' do
      it 'displays a table with an action dropdown' do
        expect(page).to have_selector(
          "[data-testid='terraform-states-table-name']",
          count: project.terraform_states.size
        )
      end

      it 'displays a correct set of actions in the action dropdown' do
        find_by_testid("terraform-state-actions-#{terraform_state.name}").click

        expect(page).to have_selector("[data-testid='terraform-state-copy-init-command']")
        expect(page).to have_selector("[data-testid='terraform-state-download']")
        expect(page).not_to have_selector("[data-testid='terraform-state-lock']")
        expect(page).not_to have_selector("[data-testid='terraform-state-unlock']")
        expect(page).not_to have_selector("[data-testid='terraform-state-remove']")
      end
    end
  end
end
