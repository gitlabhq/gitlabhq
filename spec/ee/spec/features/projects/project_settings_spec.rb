require 'spec_helper'

describe 'Edit Project Settings' do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace, path: 'gitlab', name: 'sample') }

  before do
    sign_in(user)
  end

  describe 'Merge request settings section' do
    it 'shows "Merge commit with semi-linear history " strategy' do
      visit edit_project_path(project)

      page.within '.merge-requests-feature' do
        expect(page).to have_content 'Merge commit with semi-linear history'
      end
    end
  end
end
