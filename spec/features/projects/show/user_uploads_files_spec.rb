# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User uploads files' do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, name: 'Shop', creator: user) }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when a user has write access' do
    before do
      visit(project_path(project))

      wait_for_requests
    end

    include_examples 'it uploads and commits a new text file'

    include_examples 'it uploads and commits a new image file'

    include_examples 'it uploads and commits a new pdf file'

    include_examples 'it uploads a file to a sub-directory'
  end

  context 'when a user does not have write access' do
    before do
      project2.add_reporter(user)

      visit(project_path(project2))
    end

    include_examples 'it uploads and commits a new file to a forked project'
  end

  context 'when in the empty_repo_upload experiment' do
    before do
      stub_experiments(empty_repo_upload: :candidate)

      visit(project_path(project))
    end

    context 'with an empty repo' do
      let(:project) { create(:project, :empty_repo, creator: user) }

      include_examples 'uploads and commits a new text file via "upload file" button'
    end

    context 'with a nonempty repo' do
      let(:project) { create(:project, :repository, creator: user) }

      include_examples 'uploads and commits a new text file via "upload file" button'
    end
  end
end
