require 'spec_helper'

describe 'User views an empty project' do
  let(:project) { create(:project, :empty_repo) }
  let(:user) { create(:user) }

  shared_examples 'allowing push to default branch' do
    before do
      sign_in(user)
      visit project_path(project)
    end

    it 'shows push-to-master instructions' do
      expect(page).to have_content('git push -u origin master')
    end
  end

  describe 'as a master' do
    before do
      project.add_master(user)
    end

    it_behaves_like 'allowing push to default branch'
  end

  describe 'as an admin' do
    let(:user) { create(:user, :admin) }

    it_behaves_like 'allowing push to default branch'
  end

  describe 'as a developer' do
    before do
      project.add_developer(user)
      sign_in(user)
      visit project_path(project)
    end

    it 'does not show push-to-master instructions' do
      expect(page).not_to have_content('git push -u origin master')
    end
  end
end
