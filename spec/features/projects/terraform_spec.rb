# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform', :js do
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
        expect(page).to have_content('Get started with Terraform')
      end
    end

    context 'when user has a terraform state' do
      context 'when user visits the index page' do
        before do
          visit project_terraform_index_path(project)
        end

        it 'displays a tab with states count' do
          expect(page).to have_content("States #{project.terraform_states.size}")
        end

        it 'displays a table with terraform states' do
          expect(page).to have_selector(
            '[data-testid="terraform-states-table-name"]',
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
        let(:additional_state) { create(:terraform_state, project: project) }

        it 'removes the state', :aggregate_failures, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/333640' do
          visit project_terraform_index_path(project)

          expect(page).to have_content(additional_state.name)

          find("[data-testid='terraform-state-actions-#{additional_state.name}']").click
          find('[data-testid="terraform-state-remove"]').click
          fill_in "terraform-state-remove-input-#{additional_state.name}", with: additional_state.name
          click_button 'Remove'

          expect(page).to have_content("#{additional_state.name} successfully removed")
          expect { additional_state.reload }.to raise_error ActiveRecord::RecordNotFound
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
      it 'displays a table without an action dropdown', :aggregate_failures do
        expect(page).to have_selector(
          '[data-testid="terraform-states-table-name"]',
          count: project.terraform_states.size
        )

        expect(page).not_to have_selector('[data-testid*="terraform-state-actions"]')
      end
    end
  end
end
