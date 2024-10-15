# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'View error details page', :js, :use_clean_rails_memory_store_caching, :sidekiq_inline,
  feature_category: :observability do
  include_context 'sentry error tracking context feature'

  context 'with current user as project owner' do
    before do
      sign_in(project.first_owner)

      visit details_project_error_tracking_index_path(project, issue_id: issue_id)
    end

    it_behaves_like 'error tracking show page'
  end

  context 'with current user as project guest' do
    let_it_be(:user) { create(:user) }

    before do
      project.add_guest(user)
      sign_in(user)

      visit details_project_error_tracking_index_path(project, issue_id: issue_id)
    end

    it 'renders not found' do
      expect(page).to have_content('Page not found')
    end
  end
end
