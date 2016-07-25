require 'spec_helper'

describe 'Branches', feature: true do
  let(:project) { create(:project) }
  let(:repository) { project.repository }

  before do
    login_as :user
    project.team << [@user, :developer]
  end

  describe 'Initial branches page' do
    it 'shows all the branches' do
      visit namespace_project_branches_path(project.namespace, project)

      repository.branches { |branch| expect(page).to have_content("#{branch.name}") }
      expect(page).to have_content("Protected branches can be managed in project settings")
    end
  end

  describe 'Find branches' do
    it 'shows filtered branches', js: true do
      visit namespace_project_branches_path(project.namespace, project, project.id)

      fill_in 'branch-search', with: 'fix'
      find('#branch-search').native.send_keys(:enter)

      expect(page).to have_content('fix')
      expect(find('.all-branches')).to have_selector('li', count: 1)
    end
  end
end
