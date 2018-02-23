require 'spec_helper'

feature 'Master views tags' do
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'when project has no tags' do
    let(:project) { create(:project_empty_repo) }

    before do
      visit project_path(project)
      click_on 'Add Readme'
      fill_in :commit_message, with: 'Add a README file', visible: true
      click_button 'Commit changes'
      visit project_tags_path(project)
    end

    scenario 'displays a specific message' do
      expect(page).to have_content 'Repository has no tags yet.'
    end
  end

  context 'when project has tags' do
    let(:project) { create(:project, :repository, namespace: user.namespace) }
    let(:repository) { project.repository }

    before do
      visit project_tags_path(project)
    end

    scenario 'avoids a N+1 query in branches index' do
      control_count = ActiveRecord::QueryRecorder.new { visit project_tags_path(project) }.count

      %w(one two three four five).each { |tag| repository.add_tag(user, tag, 'master', 'foo') }

      expect { visit project_tags_path(project) }.not_to exceed_query_limit(control_count)
    end

    scenario 'views the tags list page' do
      expect(page).to have_content 'v1.0.0'
    end

    scenario 'views a specific tag page' do
      click_on 'v1.0.0'

      expect(current_path).to eq(
        project_tag_path(project, 'v1.0.0'))
      expect(page).to have_content 'v1.0.0'
      expect(page).to have_content 'This tag has no release notes.'
    end

    describe 'links on the tag page' do
      scenario 'has a button to browse files' do
        click_on 'v1.0.0'

        expect(current_path).to eq(
          project_tag_path(project, 'v1.0.0'))

        click_on 'Browse files'

        expect(current_path).to eq(
          project_tree_path(project, 'v1.0.0'))
      end

      scenario 'has a button to browse commits' do
        click_on 'v1.0.0'

        expect(current_path).to eq(
          project_tag_path(project, 'v1.0.0'))

        click_on 'Browse commits'

        expect(current_path).to eq(
          project_commits_path(project, 'v1.0.0'))
      end
    end
  end
end
