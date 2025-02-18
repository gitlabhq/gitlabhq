# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User replaces files', :js, feature_category: :source_code_management do
  include DropzoneHelper

  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  let_it_be(:protected_branch) { 'protected-branch' }

  let_it_be(:project) { create(:project, :repository, name: 'Shop') }
  let_it_be(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let_it_be(:project3) do
    create(:project, :repository, name: 'Test project with protected branch', path: 'protected-branch')
  end

  let_it_be(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let_it_be(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let_it_be(:project3_protected_branch_tree_path_root_ref) do
    project_tree_path(project3, 'protected-branch', project3.repository.root_ref)
  end

  let_it_be(:user) { create(:user) }

  before do
    stub_feature_flags(blob_overflow_menu: false)
    sign_in(user)
  end

  context 'when an user has write access' do
    before_all do
      project.add_maintainer(user)
    end

    before do
      visit(project_tree_path_root_ref)
      wait_for_requests
    end

    it 'replaces an existed file with a new one' do
      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Replace')
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

      page.within('#modal-replace-blob') do
        fill_in(:commit_message, with: 'Replacement file commit message')
        click_button('Commit changes')
      end

      expect(page).to have_content('Lorem ipsum dolor sit amet')
      expect(page).to have_content('Sed ut perspiciatis unde omnis')
      expect(page).to have_content('Replacement file commit message')
    end
  end

  context 'when an user does not have write access' do
    before_all do
      project2.add_reporter(user)
    end

    before do
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
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

      page.within('#modal-replace-blob') do
        fill_in(:commit_message, with: 'Replacement file commit message')
        click_button('Commit changes')
      end

      expect(page).to have_content('Replacement file commit message')

      fork = user.fork_of(project2.reload)

      expect(page).to have_current_path(project_new_merge_request_path(fork), ignore_query: true)

      click_link('Changes')

      expect(page).to have_content('Lorem ipsum dolor sit amet')
      expect(page).to have_content('Sed ut perspiciatis unde omnis')
    end
  end

  context 'with protected branch' do
    before_all do
      project3.add_developer(user)
      project3.repository.add_branch(user, protected_branch, 'master')
      create(:protected_branch, project: project3, name: protected_branch)
    end

    it 'shows patch branch and option to create MR', :freeze_time do
      visit(project3_protected_branch_tree_path_root_ref)
      wait_for_requests

      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Replace')

      epoch = Time.zone.now.strftime('%s%L').last(5)
      expect(find_field('branch_name').value).to eq "#{user.username}-protected-branch-patch-#{epoch}"
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))
      page.within('#modal-replace-blob') do
        fill_in(:commit_message, with: 'Replacement file commit message')
        click_button('Commit changes')
      end

      expect(page).to have_content('Replacement file commit message')

      expect(page).to have_current_path(project_new_merge_request_path(project3), ignore_query: true)

      click_link('Changes')

      expect(page).to have_content('Lorem ipsum dolor sit amet')
      expect(page).to have_content('Sed ut perspiciatis unde omnis')
    end
  end
end
