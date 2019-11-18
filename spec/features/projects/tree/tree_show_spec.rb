# frozen_string_literal: true

require 'spec_helper'

describe 'Projects tree', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  # This commit has a known state on the master branch of gitlab-test
  let(:test_sha) { '7975be0116940bf2ad4321f79d02a55c5f7779aa' }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'renders tree table without errors' do
    visit project_tree_path(project, test_sha)
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('add tests for .gitattributes custom highlighting')
    expect(page).not_to have_selector('.flash-alert')
    expect(page).not_to have_selector('.label-lfs', text: 'LFS')
  end

  it 'renders tree table for a subtree without errors' do
    visit project_tree_path(project, File.join(test_sha, 'files'))
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('add spaces in whitespace file')
    expect(page).not_to have_selector('.label-lfs', text: 'LFS')
    expect(page).not_to have_selector('.flash-alert')
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

      expect(page).to have_selector('.label-lfs', text: 'LFS')
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
