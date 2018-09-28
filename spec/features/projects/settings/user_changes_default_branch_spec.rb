require 'spec_helper'

describe 'Projects > Settings > User changes default branch' do
  include Select2Helper

  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit project_settings_repository_path(project)
  end

  context 'with normal project' do
    let(:project) { create(:project, :repository, namespace: user.namespace) }

    it 'allows to change the default branch', :js do
      select2('fix', from: '#project_default_branch')

      page.within '#default-branch-settings' do
        click_button 'Save changes'
      end

      expect(find('#project_default_branch', visible: false).value).to eq 'fix'
    end
  end

  context 'with empty project' do
    let(:project) { create(:project_empty_repo, namespace: user.namespace) }

    it 'does not show default branch selector' do
      expect(page).not_to have_selector('#project_default_branch')
    end
  end
end
