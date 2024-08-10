# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Developer views tags', feature_category: :source_code_management do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when project has no tags' do
    let(:project) { create(:project_empty_repo, namespace: group) }

    before do
      project.repository.create_file(
        user,
        'README.md',
        'Example readme',
        message: 'Add README',
        branch_name: 'master')

      visit project_tags_path(project)
    end

    it 'displays a specific message' do
      expect(page).to have_content 'Repository has no tags yet'
    end
  end

  context 'when project has tags' do
    let(:project) { create(:project, :repository, namespace: group) }
    let(:repository) { project.repository }

    before do
      visit project_tags_path(project)
    end

    it 'avoids a N+1 query in branches index' do
      control = ActiveRecord::QueryRecorder.new { visit project_tags_path(project) }

      %w[one two three four five].each { |tag| repository.add_tag(user, tag, 'master', 'foo') }

      expect { visit project_tags_path(project) }.not_to exceed_query_limit(control)
    end

    it 'views the tags list page' do
      expect(page).to have_content 'v1.0.0'
    end

    it 'views a specific tag page' do
      create(:release, project: project, tag: 'v1.0.0', name: 'v1.0.0', description: nil)

      click_on 'v1.0.0'

      expect(page).to have_current_path(
        project_tag_path(project, 'v1.0.0'), ignore_query: true)
      expect(page).to have_content 'v1.0.0'
    end

    describe 'links on the tag page' do
      it 'has a button to browse files' do
        click_on 'v1.0.0'

        expect(page).to have_current_path(
          project_tag_path(project, 'v1.0.0'), ignore_query: true)

        click_on 'Browse files'

        expect(page).to have_current_path(
          project_tree_path(project, 'v1.0.0'), ignore_query: true)
      end

      it 'has a button to browse commits' do
        click_on 'v1.0.0'

        expect(page).to have_current_path(
          project_tag_path(project, 'v1.0.0'), ignore_query: true)

        click_on 'Browse commits'

        expect(page).to have_current_path(
          project_commits_path(project, 'v1.0.0'), ignore_query: true)
      end
    end
  end
end
