# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects tree', :js, feature_category: :web_ide do
  include Features::WebIdeSpecHelpers
  include RepoHelpers
  include ListboxHelpers

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

  it 'passes axe automated accessibility testing' do
    visit project_tree_path(project, test_sha)
    wait_for_requests

    expect(page).to be_axe_clean.within('.project-last-commit')
    expect(page).to be_axe_clean.within('.tree-ref-container')
    expect(page).to be_axe_clean.within('.tree-controls')
    expect(page).to be_axe_clean.within('.tree-content-holder').skipping :'link-in-text-block'
  end

  it 'renders tree table without errors' do
    visit project_tree_path(project, test_sha)
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('add tests for .gitattributes custom highlighting')
    expect(page).not_to have_selector('[data-testid="alert-danger"]')
    expect(page).not_to have_selector('[data-testid="label-lfs"]', text: 'LFS')
  end

  it 'renders tree table for a subtree without errors' do
    visit project_tree_path(project, File.join(test_sha, 'files'))
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('add spaces in whitespace file')
    expect(page).not_to have_selector('[data-testid="label-lfs"]', text: 'LFS')
    expect(page).not_to have_selector('[data-testid="alert-danger"]')
  end

  it 'renders tree table with non-ASCII filenames without errors' do
    visit project_tree_path(project, File.join(test_sha, 'encoding'))
    wait_for_requests

    expect(page).to have_selector('.tree-item')
    expect(page).to have_content('Files, encoding and much more')
    expect(page).to have_content('テスト.txt')
    expect(page).not_to have_selector('[data-testid="alert-danger"]')
  end

  context "with a tree that contains pathspec characters" do
    let(:path) { ':wq' }
    let(:filename) { File.join(path, 'test.txt') }
    let(:newrev) { project.repository.commit('master').sha }
    let(:short_newrev) { project.repository.commit('master').short_id }
    let(:message) { 'Glob characters' }

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
      expect(find_by_testid('last-commit-id-label').text).to eq(short_newrev)
    end
  end

  context 'gravatar disabled' do
    let(:gravatar_enabled) { false }

    it 'renders last commit' do
      visit project_tree_path(project, test_sha)
      wait_for_requests

      page.within('.project-last-commit') do
        expect(page).to have_selector('.gl-avatar')
        expect(page).to have_content('Merge branch')
      end
    end
  end

  context 'for signed commit' do
    it 'displays a GPG badge' do
      visit project_tree_path(project, '33f3729a45c02fc67d00adb1b8bca394b0e761d9')
      wait_for_requests

      expect(page).not_to have_selector '.js-loading-signature-badge'
      expect(page).to have_selector '.gl-badge.badge-muted'
    end

    context 'on a directory that has not changed recently' do
      it 'displays a GPG badge' do
        tree_path = File.join('eee736adc74341c5d3e26cd0438bc697f26a7575', 'subdir')
        visit project_tree_path(project, tree_path)
        wait_for_requests

        expect(page).not_to have_selector '.js-loading-signature-badge'
        expect(page).to have_selector '.gl-badge.badge-muted'
      end
    end
  end

  context 'LFS' do
    before do
      visit project_tree_path(project, File.join('master', 'files/lfs'))
      wait_for_requests
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('.tree-content-holder').skipping :'link-in-text-block'
    end

    it 'renders LFS badge on blob item' do
      expect(page).to have_selector('[data-testid="label-lfs"]', text: 'LFS')
    end
  end

  context 'web IDE' do
    before do
      stub_feature_flags(vscode_web_ide: false)
    end

    it 'opens folder in IDE' do
      visit project_tree_path(project, File.join('master', 'bar'))
      ide_visit_from_link

      wait_for_all_requests
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
      expect(page).not_to have_selector('[data-testid="alert-danger"]')
    end

    context 'for signed commit' do
      it 'displays a GPG badge' do
        visit project_tree_path(project, '33f3729a45c02fc67d00adb1b8bca394b0e761d9')
        wait_for_requests

        expect(page).not_to have_selector '.js-loading-signature-badge'
        expect(page).to have_selector '.gl-badge.badge-muted'
      end
    end
  end

  context 'ref switcher', :js do
    it 'switches ref to branch', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391780' do
      ref_selector = '.ref-selector'
      ref_name = 'fix'
      visit project_tree_path(project, 'master')

      click_button 'master'
      send_keys ref_name

      select_listbox_item ref_name

      expect(find(ref_selector)).to have_text(ref_name)
    end
  end
end
