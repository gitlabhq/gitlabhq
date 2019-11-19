# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Files > User replaces files', :js do
  include DropzoneHelper

  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end
  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when an user has write access' do
    before do
      project.add_maintainer(user)
      visit(project_tree_path_root_ref)
      wait_for_requests
    end

    it 'replaces an existed file with a new one' do
      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Replace')
      drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

      page.within('#modal-upload-blob') do
        fill_in(:commit_message, with: 'Replacement file commit message')
      end

      click_button('Replace file')

      expect(page).to have_content('Lorem ipsum dolor sit amet')
      expect(page).to have_content('Sed ut perspiciatis unde omnis')
      expect(page).to have_content('Replacement file commit message')
    end
  end

  context 'when an user does not have write access' do
    before do
      project2.add_reporter(user)
      visit(project2_tree_path_root_ref)
      wait_for_requests
    end

    it 'replaces an existed file with a new one in a forked project', :sidekiq_might_not_need_inline do
      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Replace')

      expect(page).to have_link('Fork')
      expect(page).to have_button('Cancel')

      click_link('Fork')

      expect(page).to have_content(fork_message)

      click_on('Replace')
      drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

      page.within('#modal-upload-blob') do
        fill_in(:commit_message, with: 'Replacement file commit message')
      end

      click_button('Replace file')

      expect(page).to have_content('Replacement file commit message')

      fork = user.fork_of(project2.reload)

      expect(current_path).to eq(project_new_merge_request_path(fork))

      click_link('Changes')

      expect(page).to have_content('Lorem ipsum dolor sit amet')
      expect(page).to have_content('Sed ut perspiciatis unde omnis')
    end
  end
end
