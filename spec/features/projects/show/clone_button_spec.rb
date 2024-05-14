# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > Code button', feature_category: :groups_and_projects do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project, :private, :in_group, :repository) }

  describe 'when checking project main page user' do
    context 'with an admin role' do
      before do
        project.add_owner(admin)
        sign_in(admin)
        visit project_path(project)
      end

      it 'is able to access project page' do
        expect(page).to have_content project.name
      end

      it 'sees code button', :js do
        find_by_testid('code-dropdown').click
        expect(page).to have_content _('Code')
        expect(page).to be_axe_clean.within('[data-testid="code-dropdown"]') # rubocop: disable Capybara/TestidFinders -- within_testid does not work here
      end
    end

    context 'with a guest role and no download_code access' do
      before do
        project.add_guest(guest)
        sign_in(guest)
        visit project_path(project)
      end

      it 'is able to access project page' do
        expect(page).to have_content project.name
      end

      it 'does not see code button' do
        expect(page).not_to have_content _('Code')
      end
    end
  end
end
