require 'spec_helper'

feature 'Group share lock' do
  given(:root_owner) { create(:user) }
  given(:root_group) { create(:group) }

  background do
    root_group.add_owner(root_owner)
    sign_in(root_owner)
  end

  context 'with a subgroup' do
    given!(:subgroup) { create(:group, parent: root_group) }

    context 'when enabling the parent group share lock' do
      scenario 'the subgroup share lock becomes enabled' do
        visit edit_group_path(root_group)
        check 'group_share_with_group_lock'

        click_on 'Save group'

        expect(subgroup.reload.share_with_group_lock?).to be_truthy
      end
    end

    context 'when disabling the parent group share lock (which was already enabled)' do
      background do
        visit edit_group_path(root_group)
        check 'group_share_with_group_lock'
        click_on 'Save group'
      end

      context 'and the subgroup share lock is enabled' do
        scenario 'the subgroup share lock does not change' do
          visit edit_group_path(root_group)
          uncheck 'group_share_with_group_lock'

          click_on 'Save group'

          expect(subgroup.reload.share_with_group_lock?).to be_truthy
        end
      end

      context 'but the subgroup share lock is disabled' do
        background do
          visit edit_group_path(subgroup)
          uncheck 'group_share_with_group_lock'
          click_on 'Save group'
        end

        scenario 'the subgroup share lock does not change' do
          visit edit_group_path(root_group)
          uncheck 'group_share_with_group_lock'

          click_on 'Save group'

          expect(subgroup.reload.share_with_group_lock?).to be_falsey
        end
      end
    end
  end
end
