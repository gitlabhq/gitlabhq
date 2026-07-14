# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit notes', :js, feature_category: :source_code_management do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let!(:commit_note) { create(:discussion_note_on_commit, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_commit_path(project, sample_commit.id)
  end

  it 'shows the award emoji button on a note' do
    within("#note_#{commit_note.id}") do
      expect(page).to have_testid('note-emoji-button')
    end
  end
end
