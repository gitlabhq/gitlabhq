# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contextual sidebar', :js, feature_category: :remote_development do
  context 'when context is a project' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

    before do
      sign_in(user)
      visit project_path(project)
    end

    it 'shows flyout menu on other section on hover' do
      expect(page).not_to have_link('Pipelines', href: project_pipelines_path(project))

      find_button('Build').hover
      expect(page).to have_link('Pipelines', href: project_pipelines_path(project))
    end
  end
end
