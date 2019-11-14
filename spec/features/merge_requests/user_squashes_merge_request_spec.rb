# frozen_string_literal: true

require 'spec_helper'

describe 'User squashes a merge request', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:source_branch) { 'csv' }

  let!(:original_head) { project.repository.commit('master') }

  shared_examples 'squash' do
    it 'squashes the commits into a single commit, and adds a merge commit', :sidekiq_might_not_need_inline do
      expect(page).to have_content('Merged')

      latest_master_commits = project.repository.commits_between(original_head.sha, 'master').map(&:raw)

      squash_commit = an_object_having_attributes(sha: a_string_matching(/\h{40}/),
                                                  message: a_string_starting_with(project.merge_requests.first.default_squash_commit_message),
                                                  author_name: user.name,
                                                  committer_name: user.name)

      merge_commit = an_object_having_attributes(sha: a_string_matching(/\h{40}/),
                                                 message: a_string_starting_with("Merge branch 'csv' into 'master'"),
                                                 author_name: user.name,
                                                 committer_name: user.name)

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

    uncheck 'Delete source branch'
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
    before do
      merge_request = create(:merge_request, source_project: project, target_project: project, source_branch: 'master', target_branch: 'branch-merged')

      visit project_merge_request_path(project, merge_request)
    end

    it 'does not show the squash checkbox' do
      expect(page).not_to have_field('squash')
    end
  end

  context 'when squash is enabled on merge request creation' do
    before do
      visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: source_branch })
      check 'merge_request[squash]'
      click_on 'Submit merge request'
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

  context 'when squash is not enabled on merge request creation' do
    before do
      visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: source_branch })
      click_on 'Submit merge request'
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
