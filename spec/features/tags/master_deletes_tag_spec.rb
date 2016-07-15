require 'spec_helper'

feature 'Master deletes tag', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    login_with(user)
    visit namespace_project_tags_path(project.namespace, project)
  end

  context 'from the tags list page' do
    scenario 'deletes the tag' do
      expect(page).to have_content 'v1.1.0'

      page.within('.content') do
        first('.btn-remove').click
      end

      expect(current_path).to eq(
        namespace_project_tags_path(project.namespace, project))
      expect(page).not_to have_content 'v1.1.0'
    end
  end

  context 'from a specific tag page' do
    scenario 'deletes the tag' do
      click_on 'v1.0.0'
      expect(current_path).to eq(
        namespace_project_tag_path(project.namespace, project, 'v1.0.0'))

      click_on 'Delete tag'

      expect(current_path).to eq(
        namespace_project_tags_path(project.namespace, project))
      expect(page).not_to have_content 'v1.0.0'
    end
  end
end
