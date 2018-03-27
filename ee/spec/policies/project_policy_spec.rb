require 'spec_helper'

describe ProjectPolicy do
  include ExternalAuthorizationServiceHelpers

  set(:owner) { create(:user) }
  set(:admin) { create(:admin) }
  set(:developer) { create(:user) }
  let(:project) { create(:project, :public, namespace: owner.namespace) }

  before do
    project.add_developer(developer)
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
        external_service_deny_access(owner, project)
        external_service_deny_access(developer, project)

        [developer, owner, create(:user), nil].each do |user|
          policy = described_class.new(owner, project)
          expect(policy).not_to be_allowed(:read_project)
          expect(policy).not_to be_allowed(:owner_access)
          expect(policy).not_to be_allowed(:change_namespace)
        end
      end
    end
  end
end
