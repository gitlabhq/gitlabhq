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

  context 'with an empty repo' do
    let(:project) { create(:project, :empty_repo, creator: user) }

    context 'when in the empty_repo_upload experiment' do
      before do
        stub_experiments(empty_repo_upload: :candidate)

        visit(project_path(project))
      end

      it 'uploads and commits a new text file', :js do
        click_link('Upload file')

        drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

        page.within('#modal-upload-blob') do
          fill_in(:commit_message, with: 'New commit message')
        end

        click_button('Upload file')

        wait_for_requests

        expect(page).to have_content('New commit message')
        expect(page).to have_content('Lorem ipsum dolor sit amet')
        expect(page).to have_content('Sed ut perspiciatis unde omnis')
      end
    end
  end
end
