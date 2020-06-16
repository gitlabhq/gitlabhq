# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User uploads files' do
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
      visit(project_tree_path(project))
    end

    include_examples 'it uploads and commit a new text file'

    include_examples 'it uploads and commit a new image file'

    it 'uploads a file to a sub-directory', :js do
      click_link 'files'

      page.within('.repo-breadcrumb') do
        expect(page).to have_content('files')
      end

      find('.add-to-tree').click
      click_link('Upload file')
      drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

      page.within('#modal-upload-blob') do
        fill_in(:commit_message, with: 'New commit message')
      end

      click_button('Upload file')

      expect(page).to have_content('New commit message')

      page.within('.repo-breadcrumb') do
        expect(page).to have_content('files')
        expect(page).to have_content('doc_sample.txt')
      end
    end
  end

  context 'when a user does not have write access' do
    before do
      project2.add_reporter(user)

      visit(project_tree_path(project2))
    end

    include_examples 'it uploads and commit a new file to a forked project'
  end
end
