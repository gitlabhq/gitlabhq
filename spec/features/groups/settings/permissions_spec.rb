# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group settings > Permissions', :with_current_organization, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user, organization: current_organization) }
  let_it_be_with_reload(:group) { create(:group, path: 'foo', owners: [user]) }

  before do
    sign_in(user)
  end

  describe 'enable email notifications' do
    it 'is available' do
      visit edit_group_path(group)

      expect(page).to have_selector('#group_emails_enabled')
    end

    it 'accepts the changed state' do
      visit edit_group_path(group)
      uncheck 'group_emails_enabled'

      expect { save_permissions_group }.to change { updated_emails_enabled? }.to(false)
    end
  end

  describe 'prevent sharing outside group hierarchy setting' do
    it 'updates the setting' do
      visit edit_group_path(group)

      check 'group_prevent_sharing_groups_outside_hierarchy'

      expect { save_permissions_group }.to change {
        group.reload.prevent_sharing_groups_outside_hierarchy
      }.to(true)
    end

    it 'is not present for a subgroup' do
      subgroup = create(:group, parent: group)
      visit edit_group_path(subgroup)

      expect(page).to have_text "Permissions"
      expect(page).not_to have_selector('#group_prevent_sharing_groups_outside_hierarchy')
    end
  end

  describe 'update pages access control' do
    let_it_be(:group) { create(:group, owners: [user]) }
    let_it_be(:project) { create(:project, :pages_published, namespace: group, pages_access_level: ProjectFeature::PUBLIC) }

    before do
      stub_pages_setting(access_control: true, enabled: true)
      allow(::Gitlab::Pages).to receive(:access_control_is_forced?).and_return(false)
    end

    context 'when group owner changes forced access control settings' do
      context 'when group access control is being enabled' do
        it 'project access control should be enforced' do
          visit edit_group_path(group)

          check 'group_force_pages_access_control'

          expect { save_permissions_group }.to change {
            project.private_pages?
          }.from(false).to(true)
        end
      end
    end
  end

  def save_permissions_group
    within_testid('permissions-settings') do
      click_button 'Save changes'
    end
  end

  def updated_emails_enabled?
    group.reload.clear_memoization(:emails_enabled_memoized)
    group.emails_enabled?
  end
end
