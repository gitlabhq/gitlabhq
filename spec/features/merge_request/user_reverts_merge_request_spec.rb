# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User reverts a merge request', :js, feature_category: :code_review_workflow do
  include Spec::Support::Helpers::ModalHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }

  before do
    project.add_developer(user)
    sign_in(user)

    set_cookie('new-actions-popover-viewed', 'true')
    visit(merge_request_path(merge_request))

    page.within('.mr-state-widget') do
      click_button 'Merge'
    end

    wait_for_all_requests

    page.refresh

    Sidekiq::Worker.skipping_transaction_check do
      wait_for_requests
    end
    # do not reload the page by visiting, let javascript update the page as it will validate we have loaded the modal
    # code correctly on page update that adds the `revert` button
  end

  it 'reverts a merge request', :sidekiq_might_not_need_inline, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450869' do
    revert_commit

    Sidekiq::Worker.skipping_transaction_check do
      wait_for_requests
    end

    expect(page).to have_content('The merge request has been successfully reverted.')
  end

  it 'does not revert a merge request that was previously reverted', :sidekiq_might_not_need_inline, :allowed_to_be_slow do
    revert_commit

    revert_commit

    expect(page).to have_content('Merge request revert failed:')
  end

  it 'reverts a merge request in a new merge request', :sidekiq_might_not_need_inline do
    revert_commit(create_merge_request: true)

    expect(page).to have_content('The merge request has been successfully reverted. You can now submit a merge request to get this change into the original branch.')
  end

  it 'cannot revert a merge requests for an archived project' do
    project.update!(archived: true)

    visit(merge_request_path(merge_request))

    expect(page).not_to have_link('Revert')
  end

  context 'when project merge method is fast-forward merge and squash is enabled' do
    let(:merge_request) { create(:merge_request, target_branch: 'master', source_branch: 'compare-with-merge-head-target', source_project: project, squash: true) }

    before do
      project.update!(merge_requests_ff_only_enabled: true)
    end

    it 'reverts a merge request', :sidekiq_might_not_need_inline, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/454303' do
      revert_commit

      Sidekiq::Worker.skipping_transaction_check do
        wait_for_requests
      end

      expect(page).to have_content('The merge request has been successfully reverted.')
    end
  end

  def revert_commit(create_merge_request: false)
    click_button 'Revert'

    within_modal do
      uncheck('create_merge_request') unless create_merge_request
      click_button 'Revert'
    end
  end
end
