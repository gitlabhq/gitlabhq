require 'spec_helper'

describe GroupPolicy do
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:developer) { create(:user) }
  let(:master) { create(:user) }
  let(:owner) { create(:user) }
  let(:auditor) { create(:user, :auditor) }
  let(:admin) { create(:admin) }
  let(:group) { create(:group) }

  before do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_master(master)
    group.add_owner(owner)
  end

  subject { described_class.new(current_user, group) }

  context 'when epics feature is disabled' do
    let(:current_user) { owner }

    it { is_expected.to be_disallowed(:read_epic, :create_epic, :admin_epic, :destroy_epic) }
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    let(:current_user) { owner }

    it { is_expected.to be_allowed(:read_epic, :create_epic, :admin_epic, :destroy_epic) }
  end

  context 'when LDAP sync is not enabled' do
    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_allowed(:admin_ldap_group_links) }

      context 'does not allow group owners to manage ldap' do
        before do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)
        end

        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_allowed(:admin_ldap_group_links) }
    end
  end

  context 'when LDAP sync is enabled' do
    before do
      allow(group).to receive(:ldap_synced?).and_return(true)
    end

    context 'with no user' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'guests' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'master' do
      let(:current_user) { master }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
    end

    context 'owner' do
      let(:current_user) { owner }

      context 'allow group owners to manage ldap' do
        it { is_expected.to be_allowed(:override_group_member) }
      end

      context 'does not allow group owners to manage ldap' do
        before do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)
        end

        it { is_expected.to be_disallowed(:override_group_member) }
        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:override_group_member) }
      it { is_expected.to be_allowed(:admin_ldap_group_links) }
    end
  end

  context "create_projects" do
    context 'project_creation_level enabled' do
      before do
        stub_licensed_features(project_creation_level: true)
      end

      context 'when group has no project creation level set' do
        let(:group) { create(:group, project_creation_level: nil) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:create_projects) }
        end
      end

      context 'when group has project creation level set to no one' do
        let(:group) { create(:group, project_creation_level: ::EE::Gitlab::Access::NO_ONE_PROJECT_ACCESS) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_disallowed(:create_projects) }
        end
      end

      context 'when group has project creation level set to master only' do
        let(:group) { create(:group, project_creation_level: ::EE::Gitlab::Access::MASTER_PROJECT_ACCESS) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:create_projects) }
        end
      end

      context 'when group has project creation level set to developers + master' do
        let(:group) { create(:group, project_creation_level: ::EE::Gitlab::Access::DEVELOPER_MASTER_PROJECT_ACCESS) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:create_projects) }
        end
      end
    end

    context 'project_creation_level disabled' do
      before do
        stub_licensed_features(project_creation_level: false)
      end

      context 'when group has no project creation level set' do
        let(:group) { create(:group, project_creation_level: nil) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:create_projects) }
        end
      end

      context 'when group has project creation level set to no one' do
        let(:group) { create(:group, project_creation_level: ::EE::Gitlab::Access::NO_ONE_PROJECT_ACCESS) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:create_projects) }
        end
      end

      context 'when group has project creation level set to master only' do
        let(:group) { create(:group, project_creation_level: ::EE::Gitlab::Access::MASTER_PROJECT_ACCESS) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:create_projects) }
        end
      end

      context 'when group has project creation level set to developers + master' do
        let(:group) { create(:group, project_creation_level: ::EE::Gitlab::Access::DEVELOPER_MASTER_PROJECT_ACCESS) }

        context 'reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'developer' do
          let(:current_user) { developer }

          it { is_expected.to be_disallowed(:create_projects) }
        end

        context 'master' do
          let(:current_user) { master }

          it { is_expected.to be_allowed(:create_projects) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:create_projects) }
        end
      end
    end
  end
end
