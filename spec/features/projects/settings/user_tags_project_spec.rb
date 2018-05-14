require 'spec_helper'

describe 'Projects > Settings > User tags a project' do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    sign_in(user)
    visit edit_project_path(project)
  end

  context 'when a project is archived' do
    it 'unarchives a project' do
      fill_in 'Tags', with: 'tag1, tag2'

      page.within '.general-settings' do
        click_button 'Save changes'
      end

      expect(find_field('Tags').value).to eq 'tag1, tag2'
    end
  end
end
