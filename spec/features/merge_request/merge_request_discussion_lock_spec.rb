# frozen_string_literal: true
# TODO use shared examples to merge this spec with discussion_lock_spec.rb
# https://gitlab.com/gitlab-org/gitlab/-/issues/255910

require 'spec_helper'

RSpec.describe 'Merge Request Discussion Lock', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }
  let(:moved_mr_sidebar_enabled) { false }

  before do
    stub_feature_flags(moved_mr_sidebar: moved_mr_sidebar_enabled)
    sign_in(user)
  end

  context 'moved sidebar flag disabled' do
    context 'when a user is a team member' do
      before do
        project.add_developer(user)
      end

      context 'when the discussion is unlocked' do
        it 'the user can lock the merge_request' do
          visit project_merge_request_path(merge_request.project, merge_request)

          expect(find('.issuable-sidebar')).to have_content('Unlocked')

          page.within('.issuable-sidebar') do
            find('.lock-edit').click
            click_button('Lock')
          end

          expect(find('[data-testid="lock-status"]')).to have_content('Locked')
        end
      end

      context 'when the discussion is locked' do
        before do
          merge_request.update_attribute(:discussion_locked, true)
          visit project_merge_request_path(merge_request.project, merge_request)
        end

        it 'the user can unlock the merge_request' do
          expect(find('.issuable-sidebar')).to have_content('Locked')

          page.within('.issuable-sidebar') do
            find('.lock-edit').click
            click_button('Unlock')
          end

          expect(find('[data-testid="lock-status"]')).to have_content('Unlocked')
        end
      end
    end

    context 'when a user is not a team member' do
      context 'when the discussion is unlocked' do
        before do
          visit project_merge_request_path(merge_request.project, merge_request)
        end

        it 'the user can not lock the merge_request' do
          expect(find('.issuable-sidebar')).to have_content('Unlocked')
          expect(find('.issuable-sidebar')).not_to have_selector('.lock-edit')
        end
      end

      context 'when the discussion is locked' do
        before do
          merge_request.update_attribute(:discussion_locked, true)
          visit project_merge_request_path(merge_request.project, merge_request)
        end

        it 'the user can not unlock the merge_request' do
          expect(find('.issuable-sidebar')).to have_content('Locked')
          expect(find('.issuable-sidebar')).not_to have_selector('.lock-edit')
        end
      end
    end
  end

  context 'moved sidebar flag enabled' do
    let(:moved_mr_sidebar_enabled) { true }

    context 'when the discussion is unlocked' do
      before do
        visit project_merge_request_path(merge_request.project, merge_request)
      end

      it 'the user can lock the merge_request' do
        find('[data-testid="merge-request-actions"]').click

        expect(page).to have_content('Lock merge request')
      end
    end

    context 'when the discussion is locked' do
      before do
        merge_request.update_attribute(:discussion_locked, true)
        visit project_merge_request_path(merge_request.project, merge_request)
      end

      it 'the user can unlock the merge_request' do
        find('[data-testid="merge-request-actions"]').click

        expect(page).to have_content('Unlock merge request')
      end
    end
  end
end
