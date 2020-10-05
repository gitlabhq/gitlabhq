# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects tree', :js do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:gravatar_enabled) { true }

  # This commit has a known state on the master branch of gitlab-test
  let(:test_sha) { '7975be0116940bf2ad4321f79d02a55c5f7779aa' }

  before do
    stub_application_setting(gravatar_enabled: gravatar_enabled)

    project.add_maintainer(user)
    sign_in(user)
  end

  it 'renders tree table without errors' do
    visit project_tree_path(project, test_sha)
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('add tests for .gitattributes custom highlighting')
    expect(page).not_to have_selector('.flash-alert')
    expect(page).not_to have_selector('[data-qa-selector="label-lfs"]', text: 'LFS')
  end

  it 'renders tree table for a subtree without errors' do
    visit project_tree_path(project, File.join(test_sha, 'files'))
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('add spaces in whitespace file')
    expect(page).not_to have_selector('[data-qa-selector="label-lfs"]', text: 'LFS')
    expect(page).not_to have_selector('.flash-alert')
  end

  it 'renders tree table with non-ASCII filenames without errors' do
    visit project_tree_path(project, File.join(test_sha, 'encoding'))
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('Files, encoding and much more')
    expect(page).to have_content('テスト.txt')
    expect(page).not_to have_selector('.flash-alert')
  end

  context "with a tree that contains pathspec characters" do
    let(:path) { ':wq' }
    let(:filename) { File.join(path, 'test.txt') }
    let(:newrev) { project.repository.commit('master').sha }
    let(:short_newrev) { project.repository.commit('master').short_id }
    let(:message) { 'Glob characters'}

    before do
      create_file_in_repo(project, 'master', 'master', filename, 'Test file', commit_message: message)
      visit project_tree_path(project, File.join('master', path))
      wait_for_requests
    end

    it "renders tree table without errors" do
      expect(page).to have_selector('.tree-item')
      expect(page).to have_content('test.txt')
      expect(page).to have_content(message)

      # Check last commit
      expect(find('.commit-content').text).to include(message)
      expect(find('.js-commit-sha-group').text).to eq(short_newrev)
    end
  end

  context 'gravatar disabled' do
    let(:gravatar_enabled) { false }

    it 'renders last commit' do
      visit project_tree_path(project, test_sha)
      wait_for_requests

      page.within('.project-last-commit') do
        expect(page).to have_selector('.user-avatar-link')
        expect(page).to have_content('Merge branch')
      end
    end
  end

  context 'for signed commit' do
    it 'displays a GPG badge' do
      visit project_tree_path(project, '33f3729a45c02fc67d00adb1b8bca394b0e761d9')
      wait_for_requests

      expect(page).not_to have_selector '.gpg-status-box.js-loading-gpg-badge'
      expect(page).to have_selector '.gpg-status-box.invalid'
    end

    context 'on a directory that has not changed recently' do
      it 'displays a GPG badge' do
        tree_path = File.join('eee736adc74341c5d3e26cd0438bc697f26a7575', 'subdir')
        visit project_tree_path(project, tree_path)
        wait_for_requests

        expect(page).not_to have_selector '.gpg-status-box.js-loading-gpg-badge'
        expect(page).to have_selector '.gpg-status-box.invalid'
      end
    end
  end

  context 'LFS' do
    it 'renders LFS badge on blob item' do
      visit project_tree_path(project, File.join('master', 'files/lfs'))

      expect(page).to have_selector('[data-qa-selector="label-lfs"]', text: 'LFS')
    end
  end

  context 'web IDE' do
    it 'opens folder in IDE' do
      visit project_tree_path(project, File.join('master', 'bar'))

      click_link 'Web IDE'

      wait_for_requests
      find('.ide-file-list')
      wait_for_requests
      expect(page).to have_selector('.is-open', text: 'bar')
    end
  end

  context 'for subgroups' do
    let(:group) { create(:group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:project) { create(:project, :repository, group: subgroup) }

    it 'renders tree table without errors' do
      visit project_tree_path(project, 'master')
      wait_for_requests

      expect(page).to have_selector('.tree-item')
      expect(page).not_to have_selector('.flash-alert')
    end

    context 'for signed commit' do
      it 'displays a GPG badge' do
        visit project_tree_path(project, '33f3729a45c02fc67d00adb1b8bca394b0e761d9')
        wait_for_requests

        expect(page).not_to have_selector '.gpg-status-box.js-loading-gpg-badge'
        expect(page).to have_selector '.gpg-status-box.invalid'
      end
    end
  end
end
