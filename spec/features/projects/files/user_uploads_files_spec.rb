# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User uploads files' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, name: 'Shop', creator: user) }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when a user has write access' do
    before do
      visit(project_tree_path(project))

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

      visit(project_tree_path(project2))
    end

    include_examples 'it uploads and commits a new file to a forked project'
  end
end
