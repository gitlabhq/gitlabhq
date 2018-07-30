require 'spec_helper'

describe ProjectPolicy do
  include ExternalAuthorizationServiceHelpers

  set(:owner) { create(:user) }
  set(:admin) { create(:admin) }
  set(:maintainer) { create(:user) }
  set(:developer) { create(:user) }
  set(:reporter) { create(:user) }
  set(:guest) { create(:user) }
  let(:project) { create(:project, :public, namespace: owner.namespace) }

  before do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)
  end

  context 'admin_mirror' do
    context 'with remote mirror setting enabled' do
      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with developer' do
        subject do
          described_class.new(developer, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirror setting disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirrors feature disabled' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_disallowed(:admin_mirror)
        end
      end
    end

    context 'with remote mirrors feature enabled' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      context 'with admin' do
        subject do
          described_class.new(admin, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end

      context 'with owner' do
        subject do
          described_class.new(owner, project)
        end

        it do
          is_expected.to be_allowed(:admin_mirror)
        end
      end
    end
  end

  context 'reading a project' do
    it 'allows access when a user has read access to the repo' do
      expect(described_class.new(owner, project)).to be_allowed(:read_project)
      expect(described_class.new(developer, project)).to be_allowed(:read_project)
      expect(described_class.new(admin, project)).to be_allowed(:read_project)
    end

    it 'never checks the external service' do
      expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(described_class.new(owner, project)).to be_allowed(:read_project)
    end

    context 'with an external authorization service' do
      before do
        enable_external_authorization_service_check
      end

      it 'allows access when the external service allows it' do
        external_service_allow_access(owner, project)
        external_service_allow_access(developer, project)

        expect(described_class.new(owner, project)).to be_allowed(:read_project)
        expect(described_class.new(developer, project)).to be_allowed(:read_project)
      end

      it 'does not check the external service for admins and allows access' do
        expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        expect(described_class.new(admin, project)).to be_allowed(:read_project)
      end

      it 'allows auditors' do
        stub_licensed_features(auditor_user: true)
        auditor = create(:user, :auditor)

        expect(described_class.new(auditor, project)).to be_allowed(:read_project)
      end

      it 'prevents all but seeing a public project in a list when access is denied' do
        [developer, owner, build(:user), nil].each do |user|
          external_service_deny_access(user, project)
          policy = described_class.new(user, project)

          expect(policy).not_to be_allowed(:read_project)
          expect(policy).not_to be_allowed(:owner_access)
          expect(policy).not_to be_allowed(:change_namespace)
        end
      end

      it 'passes the full path to external authorization for logging purposes' do
        expect(EE::Gitlab::ExternalAuthorization)
          .to receive(:access_allowed?).with(owner, 'default_label', project.full_path).and_call_original

        described_class.new(owner, project).allowed?(:read_project)
      end
    end
  end

  describe 'read_vulnerability_feedback' do
    subject { described_class.new(current_user, project) }

    context 'with public project' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:read_vulnerability_feedback) }
    end

    context 'with private project' do
      let(:current_user) { admin }
      let(:project) { create(:project, :private, namespace: owner.namespace) }

      context 'with admin' do
        let(:current_user) { admin }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with developer' do
        let(:current_user) { developer }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with guest' do
        let(:current_user) { guest }

        it { is_expected.to be_allowed(:read_vulnerability_feedback) }
      end

      context 'with non member' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_disallowed(:read_vulnerability_feedback) }
      end

      context 'with anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:read_vulnerability_feedback) }
      end
    end
  end

  describe 'admin_vulnerability_feedback' do
    subject { described_class.new(current_user, project) }

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:admin_vulnerability_feedback) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:admin_vulnerability_feedback) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:admin_vulnerability_feedback) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:admin_vulnerability_feedback) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:admin_vulnerability_feedback) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:admin_vulnerability_feedback) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:admin_vulnerability_feedback) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:admin_vulnerability_feedback) }
    end
  end

  describe 'read_project_security_dashboard' do
    subject { described_class.new(current_user, project) }

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_project_security_dashboard) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_project_security_dashboard) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_project_security_dashboard) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_project_security_dashboard) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:read_project_security_dashboard) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_project_security_dashboard) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:read_project_security_dashboard) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_project_security_dashboard) }
    end
  end

  describe 'admin_license_management' do
    before do
      stub_licensed_features(license_management: true)
    end

    subject { described_class.new(current_user, project) }

    context 'without license management feature available' do
      before do
        stub_licensed_features(license_management: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:admin_software_license_policy) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:admin_software_license_policy) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:admin_software_license_policy) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:admin_software_license_policy) }
    end
  end

  describe 'read_license_management' do
    before do
      stub_licensed_features(license_management: true)
    end

    subject { described_class.new(current_user, project) }

    context 'without license management feature available' do
      before do
        stub_licensed_features(license_management: false)
      end

      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:read_software_license_policy) }
    end

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:read_software_license_policy) }
    end
  end
end
