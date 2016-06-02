require 'spec_helper'

feature 'Master views tags', feature: true do
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_with(user)
  end

  context 'when project has no tags' do
    let(:project) { create(:project_empty_repo) }
    before do
      visit namespace_project_path(project.namespace, project)
      click_on 'README'
      fill_in :commit_message, with: 'Add a README file', visible: true
      # Remove pre-receive hook so we can push without auth
      FileUtils.rm_f(File.join(project.repository.path, 'hooks', 'pre-receive'))
      click_button 'Commit Changes'
      visit namespace_project_tags_path(project.namespace, project)
    end

    scenario 'displays a specific message' do
      expect(page).to have_content 'Repository has no tags yet.'
    end
  end

  context 'when project has tags' do
    let(:project) { create(:project, namespace: user.namespace) }
    before do
      visit namespace_project_tags_path(project.namespace, project)
    end

    scenario 'views the tags list page' do
      expect(page).to have_content 'v1.0.0'
    end

    scenario 'views a specific tag page' do
      click_on 'v1.0.0'

      expect(current_path).to eq(
        namespace_project_tag_path(project.namespace, project, 'v1.0.0'))
      expect(page).to have_content 'v1.0.0'
      expect(page).to have_content 'This tag has no release notes.'
    end

    describe 'links on the tag page' do
      scenario 'has a button to browse files' do
        click_on 'v1.0.0'

        expect(current_path).to eq(
          namespace_project_tag_path(project.namespace, project, 'v1.0.0'))

        click_on 'Browse files'

        expect(current_path).to eq(
          namespace_project_tree_path(project.namespace, project, 'v1.0.0'))
      end

      scenario 'has a button to browse commits' do
        click_on 'v1.0.0'

        expect(current_path).to eq(
          namespace_project_tag_path(project.namespace, project, 'v1.0.0'))

        click_on 'Browse commits'

        expect(current_path).to eq(
          namespace_project_commits_path(project.namespace, project, 'v1.0.0'))
      end
    end
  end
end
