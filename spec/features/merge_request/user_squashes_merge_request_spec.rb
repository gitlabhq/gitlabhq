# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User squashes a merge request', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:source_branch) { 'csv' }
  let(:protected_source_branch) { false }

  let!(:original_head) { project.repository.commit('master') }

  shared_examples 'squash' do
    it 'squashes the commits into a single commit, and adds a merge commit', :sidekiq_might_not_need_inline do
      expect(page).to have_content('Merged')

      latest_master_commits = project.repository.commits_between(original_head.sha, 'master').map(&:raw)

      squash_commit = an_object_having_attributes(
        sha: a_string_matching(/\h{40}/),
        message: a_string_starting_with(project.merge_requests.first.default_squash_commit_message),
        author_name: user.name,
        committer_name: user.name
      )

      merge_commit = an_object_having_attributes(
        sha: a_string_matching(/\h{40}/),
        message: a_string_starting_with("Merge branch '#{source_branch}' into 'master'"),
        author_name: user.name,
        committer_name: user.name
      )

      expect(project.repository).not_to be_merged_to_root_ref(source_branch)
      expect(latest_master_commits).to match([squash_commit, merge_commit])
    end
  end

  shared_examples 'no squash' do
    it 'accepts the merge request without squashing', :sidekiq_might_not_need_inline do
      expect(page).to have_content('Merged')
      expect(project.repository).to be_merged_to_root_ref(source_branch)
    end
  end

  def accept_mr
    expect(page).to have_button('Merge')

    uncheck 'Delete source branch' unless protected_source_branch
    click_on 'Merge'
  end

  before do
    # Prevent source branch from being removed so we can use be_merged_to_root_ref
    # method to check if squash was performed or not
    allow_next_instance_of(MergeRequest) do |instance|
      allow(instance).to receive(:force_remove_source_branch?).and_return(false)
    end
    project.add_maintainer(user)

    sign_in user
  end

  context 'when the MR has only one commit' do
    let(:source_branch) { 'feature' }
    let(:target_branch) { 'master' }
    let(:source_sha) { project.commit(source_branch).sha }
    let(:target_sha) { project.commit(target_branch).sha }

    before do
      visit project_new_merge_request_path(project, merge_request: { target_branch: target_branch, source_branch: source_branch })
      check 'merge_request[squash]'
      click_on 'Create merge request'
      wait_for_requests
    end

    context 'when squash message differs from existing commit message' do
      before do
        accept_mr
      end

      include_examples 'squash'
    end

    context 'when squash message is the same as existing commit message' do
      before do
        find_by_testid('widget_edit_commit_message').click
        fill_in('Squash commit message', with: project.commit(source_branch).safe_message)
        accept_mr
      end

      include_examples 'no squash'
    end
  end

  context 'when squash is enabled on merge request creation', :sidekiq_might_not_need_inline do
    before do
      visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: source_branch })
      check 'merge_request[squash]'
      click_on 'Create merge request'
      wait_for_requests
    end

    it 'shows the squash checkbox as checked' do
      expect(page).to have_checked_field('squash')
    end

    context 'when accepting with squash checked' do
      before do
        accept_mr
      end

      include_examples 'squash'
    end

    context 'when accepting and unchecking squash' do
      before do
        uncheck 'squash'
        accept_mr
      end

      include_examples 'no squash'
    end
  end

  context 'when squash is not enabled on merge request creation', :sidekiq_might_not_need_inline do
    before do
      visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: source_branch })
      click_on 'Create merge request'
      wait_for_requests
    end

    it 'shows the squash checkbox as unchecked' do
      expect(page).to have_unchecked_field('squash')
    end

    context 'when accepting and checking squash' do
      before do
        check 'squash'
        accept_mr
      end

      include_examples 'squash'
    end

    context 'when accepting with squash unchecked' do
      before do
        accept_mr
      end

      include_examples 'no squash'
    end
  end
end
