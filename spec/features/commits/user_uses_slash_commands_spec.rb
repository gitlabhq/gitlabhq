require 'rails_helper'

describe 'Commit > User uses quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers
  include RepoHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:commit) { project.commit }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_commit_path(project, commit.id)
  end

  describe 'Tagging a commit' do
    let(:tag_name) { 'v1.2.3' }
    let(:tag_message) { 'Stable release' }
    let(:truncated_commit_sha) { Commit.truncate_sha(commit.sha) }

    it 'tags this commit' do
      add_note("/tag #{tag_name} #{tag_message}")

      expect(page).to have_content 'Commands applied'
      expect(page).to have_content "tagged commit #{truncated_commit_sha}"
      expect(page).to have_content tag_name

      visit project_tag_path(project, tag_name)
      expect(page).to have_content tag_name
      expect(page).to have_content tag_message
      expect(page).to have_content truncated_commit_sha
    end

    describe 'preview', :js do
      it 'removes quick action from note and explains it' do
        preview_note("/tag #{tag_name} #{tag_message}")

        expect(page).not_to have_content '/tag'
        expect(page).to have_content %{Tags this commit to #{tag_name} with "#{tag_message}"}
        expect(page).to have_content tag_name
      end
    end
  end
end
