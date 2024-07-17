# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group share with group lock', feature_category: :groups_and_projects do
  let(:root_owner) { create(:user) }
  let(:root_group) { create(:group) }

  before do
    root_group.add_owner(root_owner)
    sign_in(root_owner)
  end

  context 'with a subgroup' do
    let!(:subgroup) { create(:group, parent: root_group) }

    context 'when enabling the parent group share with group lock' do
      it 'the subgroup share with group lock becomes enabled' do
        visit edit_group_path(root_group)

        enable_group_lock

        expect(subgroup.reload.share_with_group_lock?).to be_truthy
      end
    end

    context 'when disabling the parent group share with group lock (which was already enabled)' do
      before do
        visit edit_group_path(root_group)

        enable_group_lock
      end

      context 'and the subgroup share with group lock is enabled' do
        it 'the subgroup share with group lock does not change' do
          visit edit_group_path(root_group)

          disable_group_lock

          expect(subgroup.reload.share_with_group_lock?).to be_truthy
        end
      end

      context 'but the subgroup share with group lock is disabled' do
        before do
          visit edit_group_path(subgroup)

          disable_group_lock
        end

        it 'the subgroup share with group lock does not change' do
          visit edit_group_path(root_group)

          disable_group_lock

          expect(subgroup.reload.share_with_group_lock?).to be_falsey
        end
      end
    end
  end

  def enable_group_lock
    within_testid('permissions-settings') do
      check 'group_share_with_group_lock'
      click_on 'Save changes'
    end
  end

  def disable_group_lock
    within_testid('permissions-settings') do
      uncheck 'group_share_with_group_lock'
      click_on 'Save changes'
    end
  end
end
