require 'spec_helper'

describe EE::ProtectedRefAccess do
  include ExternalAuthorizationServiceHelpers
  included_in_classes = [ProtectedBranch::MergeAccessLevel,
                         ProtectedBranch::PushAccessLevel,
                         ProtectedTag::CreateAccessLevel]

  included_in_classes.each do |included_in_class|
    context "in #{included_in_class}" do
      let(:factory_name) { included_in_class.name.underscore.tr('/', '_') }
      let(:access_level) { build(factory_name) }

      it "#{included_in_class} includes {described_class}" do
        expect(included_in_class.included_modules).to include(described_class)
      end

      context 'with the `protected_refs_for_users` feature disabled' do
        before do
          stub_licensed_features(protected_refs_for_users: false)
        end

        it "allows creating an #{included_in_class} with a group" do
          access_level.group = create(:group)

          expect(access_level).not_to be_valid
          expect(access_level.errors).to include(:group)
        end

        it "allows creating an #{included_in_class} with a user" do
          access_level.user = create(:user)

          expect(access_level).not_to be_valid
          expect(access_level.errors).to include(:user)
        end
      end

      context 'with the `protected_refs_for_users` feature enabled' do
        before do
          stub_licensed_features(protected_refs_for_users: true)
        end

        it "allows creating an #{included_in_class} with a group" do
          access_level.group = create(:group)

          expect(access_level).to be_valid
        end

        it "allows creating an #{included_in_class} with a user" do
          access_level.user = create(:user)

          expect(access_level).to be_valid
        end
      end

      it 'requires access_level if no user or group is specified' do
        subject = build(factory_name, access_level: nil)

        expect(subject).not_to be_valid
      end

      it "doesn't require access_level if user specified" do
        subject = build(factory_name, access_level: nil, user: create(:user))

        expect(subject).to be_valid
      end

      it "doesn't require access_level if group specified" do
        subject = build(factory_name, access_level: nil, group: create(:group))

        expect(subject).to be_valid
      end
    end
  end

  describe '#check_access' do
    subject(:protected_ref_access) do
      create(:protected_branch, :masters_can_push).push_access_levels.first
    end

    let(:project) { protected_ref_access.project }

    it 'is false if external authorization denies access' do
      master = create(:user)
      project.add_master(master)
      external_service_deny_access(master, project)

      expect(protected_ref_access.check_access(master)).to be_falsey
    end
  end
end
