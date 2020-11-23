# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views an empty project' do
  let(:project) { create(:project, :empty_repo) }
  let(:user) { create(:user) }

  shared_examples 'allowing push to default branch' do
    it 'shows push-to-master instructions' do
      visit project_path(project)

      expect(page).to have_content('git push -u origin master')
    end
  end

  describe 'as a maintainer' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it_behaves_like 'allowing push to default branch'
  end

  describe 'as an admin' do
    let(:user) { create(:user, :admin) }

    context 'when admin mode is enabled' do
      before do
        sign_in(user)
        gitlab_enable_admin_mode_sign_in(user)
      end

      it_behaves_like 'allowing push to default branch'
    end

    context 'when admin mode is disabled' do
      it 'does not show push-to-master instructions' do
        visit project_path(project)

        expect(page).not_to have_content('git push -u origin master')
      end
    end
  end

  describe 'as a developer' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'does not show push-to-master instructions' do
      visit project_path(project)

      expect(page).not_to have_content('git push -u origin master')
    end
  end
end
