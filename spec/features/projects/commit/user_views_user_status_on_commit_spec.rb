# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Commit > View user status', feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:commit_author) { create(:user, email: sample_commit.author_email) }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  subject { visit(project_commit_path(project, sample_commit.id)) }

  describe 'status for the commit author' do
    it_behaves_like 'showing user status' do
      let(:user_with_status) { commit_author }
    end
  end

  describe 'status for a comment on the commit' do
    let(:note) { create(:note, :on_commit, project: project) }

    it_behaves_like 'showing user status' do
      let(:user_with_status) { note.author }
    end
  end

  describe 'status for a diff note on the commit', :js do
    let(:note) { create(:diff_note_on_commit, project: project) }

    it_behaves_like 'showing user status' do
      let(:user_with_status) { note.author }
    end
  end
end
