# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reportable note on commit', :js do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'a normal note' do
    let!(:note) { create(:note_on_commit, commit_id: sample_commit.id, project: project) }

    before do
      visit project_commit_path(project, sample_commit.id)
    end

    it_behaves_like 'reportable note', 'commit'
  end

  context 'a diff note' do
    let!(:note) { create(:diff_note_on_commit, commit_id: sample_commit.id, project: project) }

    before do
      visit project_commit_path(project, sample_commit.id)
    end

    it_behaves_like 'reportable note', 'commit'
  end
end
