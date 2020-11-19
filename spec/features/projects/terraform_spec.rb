# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform', :js do
  let_it_be(:project) { create(:project) }

  let(:user) { project.creator }

  before do
    gitlab_sign_in(user)
  end

  context 'when user does not have any terraform states and visits index page' do
    before do
      visit project_terraform_index_path(project)
    end

    it 'sees an empty state' do
      expect(page).to have_content('Get started with Terraform')
    end
  end

  context 'when user has a terraform state' do
    let_it_be(:terraform_state) { create(:terraform_state, :locked, project: project) }

    context 'when user visits the index page' do
      before do
        visit project_terraform_index_path(project)
      end

      it 'displays a tab with states count' do
        expect(page).to have_content("States #{project.terraform_states.size}")
      end

      it 'displays a table with terraform states' do
        expect(page).to have_selector(
          '[data-testid="terraform-states-table"] tbody tr',
          count: project.terraform_states.size
        )
      end

      it 'displays terraform information' do
        expect(page).to have_content(terraform_state.name)
      end
    end
  end
end
