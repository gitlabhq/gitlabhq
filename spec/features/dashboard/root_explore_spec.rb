# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root explore', :saas, feature_category: :shared do
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:archived_project) { create(:project, :archived) }
  let_it_be(:internal_project) { create(:project, :internal) }
  let_it_be(:private_project) { create(:project, :private) }

  context 'when logged in' do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
      visit explore_projects_path
    end

    include_examples 'shows public and internal projects'
  end

  context 'when not logged in' do
    before do
      visit explore_projects_path
    end

    include_examples 'shows public projects'
  end

  describe 'project language dropdown', :js do
    it 'is conditionally rendered' do
      visit explore_projects_path
      find_by_testid('filtered-search-term-input').click

      expect(page).to have_link('Language')
    end
  end
end
