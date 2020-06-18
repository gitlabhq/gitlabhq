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
    end

    include_examples 'it uploads and commit a new text file'

    include_examples 'it uploads and commit a new image file'
  end

  context 'when a user does not have write access' do
    before do
      project2.add_reporter(user)

      visit(project_path(project2))
    end

    include_examples 'it uploads and commit a new file to a forked project'
  end
end
