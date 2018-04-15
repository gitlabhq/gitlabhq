require 'spec_helper'

describe 'User uses shortcuts', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_path(project))
  end

  context 'when navigating to the Project pages' do
    it 'redirects to the details page' do
      find('body').native.send_key('g')
      find('body').native.send_key('p')

      expect(page).to have_active_navigation('Project')
      expect(page).to have_active_sub_navigation('Details')
    end

    it 'redirects to the activity page' do
      find('body').native.send_key('g')
      find('body').native.send_key('e')

      expect(page).to have_active_navigation('Project')
      expect(page).to have_active_sub_navigation('Activity')
    end
  end

  context 'when navigating to the Repository pages' do
    it 'redirects to the repository files page' do
      find('body').native.send_key('g')
      find('body').native.send_key('f')

      expect(page).to have_active_navigation('Repository')
      expect(page).to have_active_sub_navigation('Files')
    end

    it 'redirects to the repository commits page' do
      find('body').native.send_key('g')
      find('body').native.send_key('c')

      expect(page).to have_active_navigation('Repository')
      expect(page).to have_active_sub_navigation('Commits')
    end

    it 'redirects to the repository graph page' do
      find('body').native.send_key('g')
      find('body').native.send_key('n')

      expect(page).to have_active_navigation('Repository')
      expect(page).to have_active_sub_navigation('Graph')
    end

    it 'redirects to the repository charts page' do
      find('body').native.send_key('g')
      find('body').native.send_key('d')

      expect(page).to have_active_navigation('Repository')
      expect(page).to have_active_sub_navigation('Charts')
    end
  end

  context 'when navigating to the Issues pages' do
    it 'redirects to the issues list page' do
      find('body').native.send_key('g')
      find('body').native.send_key('i')

      expect(page).to have_active_navigation('Issues')
      expect(page).to have_active_sub_navigation('List')
    end

    it 'redirects to the new issue page' do
      find('body').native.send_key('i')

      expect(page).to have_content(project.title)
    end
  end

  context 'when navigating to the Merge Requests pages' do
    it 'redirects to the merge requests page' do
      find('body').native.send_key('g')
      find('body').native.send_key('m')

      expect(page).to have_active_navigation('Merge Requests')
    end
  end

  context 'when navigating to the Snippets pages' do
    it 'redirects to the snippets page' do
      find('body').native.send_key('g')
      find('body').native.send_key('s')

      expect(page).to have_active_navigation('Snippets')
    end
  end

  context 'when navigating to the Wiki pages' do
    it 'redirects to the wiki page' do
      find('body').native.send_key('g')
      find('body').native.send_key('w')

      expect(page).to have_active_navigation('Wiki')
    end
  end
end
