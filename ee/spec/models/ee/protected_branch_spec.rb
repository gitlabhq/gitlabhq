require 'spec_helper'

describe ProtectedBranch do
  subject { create(:protected_branch) }

  let(:project) { subject.project }
  let(:user) { create(:user) }

  shared_examples 'uniqueness validation' do |access_level_class|
    let(:factory_name) { access_level_class.to_s.underscore.sub('/', '_').to_sym }
    let(:association_name) { access_level_class.to_s.underscore.sub('protected_branch/', '').pluralize.to_sym }

    human_association_name = access_level_class.to_s.underscore.humanize.sub('Protected branch/', '')

    context "while checking uniqueness of a role-based #{human_association_name}" do
      it "allows a single #{human_association_name} for a role (per protected branch)" do
        first_protected_branch = create(:protected_branch, default_access_level: false)
        second_protected_branch = create(:protected_branch, default_access_level: false)

        first_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)
        second_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)

        expect(first_protected_branch).to be_valid
        expect(second_protected_branch).to be_valid

        first_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)
        expect(first_protected_branch).to be_invalid
        expect(first_protected_branch.errors.full_messages.first).to match("access level has already been taken")
      end

      it "does not count a user-based #{human_association_name} with an `access_level` set" do
        protected_branch = create(:protected_branch, default_access_level: false)

        protected_branch.send(association_name) << build(factory_name, user: user, access_level: Gitlab::Access::MASTER)
        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)

        expect(protected_branch).to be_valid
      end

      it "does not count a group-based #{human_association_name} with an `access_level` set" do
        group = create(:group)
        protected_branch = create(:protected_branch, default_access_level: false)

        protected_branch.send(association_name) << build(factory_name, group: group, access_level: Gitlab::Access::MASTER)
        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)

        expect(protected_branch).to be_valid
      end
    end

    context "while checking uniqueness of a user-based #{human_association_name}" do
      it "allows a single #{human_association_name} for a user (per protected branch)" do
        first_protected_branch = create(:protected_branch, default_access_level: false)
        second_protected_branch = create(:protected_branch, default_access_level: false)

        first_protected_branch.send(association_name) << build(factory_name, user: user)
        second_protected_branch.send(association_name) << build(factory_name, user: user)

        expect(first_protected_branch).to be_valid
        expect(second_protected_branch).to be_valid

        first_protected_branch.send(association_name) << build(factory_name, user: user)
        expect(first_protected_branch).to be_invalid
        expect(first_protected_branch.errors.full_messages.first).to match("user has already been taken")
      end

      it "ignores the `access_level` while validating a user-based #{human_association_name}" do
        protected_branch = create(:protected_branch, default_access_level: false)

        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)
        protected_branch.send(association_name) << build(factory_name, user: user, access_level: Gitlab::Access::MASTER)

        expect(protected_branch).to be_valid
      end
    end

    context "while checking uniqueness of a group-based #{human_association_name}" do
      let(:group) { create(:group) }

      it "allows a single #{human_association_name} for a group (per protected branch)" do
        first_protected_branch = create(:protected_branch, default_access_level: false)
        second_protected_branch = create(:protected_branch, default_access_level: false)

        first_protected_branch.send(association_name) << build(factory_name, group: group)
        second_protected_branch.send(association_name) << build(factory_name, group: group)

        expect(first_protected_branch).to be_valid
        expect(second_protected_branch).to be_valid

        first_protected_branch.send(association_name) << build(factory_name, group: group)
        expect(first_protected_branch).to be_invalid
        expect(first_protected_branch.errors.full_messages.first).to match("group has already been taken")
      end

      it "ignores the `access_level` while validating a group-based #{human_association_name}" do
        protected_branch = create(:protected_branch, default_access_level: false)

        protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)
        protected_branch.send(association_name) << build(factory_name, group: group, access_level: Gitlab::Access::MASTER)

        expect(protected_branch).to be_valid
      end
    end
  end

  it_behaves_like 'uniqueness validation', ProtectedBranch::MergeAccessLevel
  it_behaves_like 'uniqueness validation', ProtectedBranch::PushAccessLevel

  describe '#can_unprotect?' do
    let(:admin) { create(:user, :admin) }
    let(:master) do
      create(:user).tap { |user| project.add_master(user) }
    end

    context 'without unprotect_access_levels' do
      it "doesn't add any additional restriction" do
        expect(subject.can_unprotect?(user)).to eq true
      end
    end

    context 'with access level set to MASTER' do
      before do
        subject.unprotect_access_levels.create!(access_level: Gitlab::Access::MASTER)
      end

      it 'defaults to requiring master access' do
        expect(subject.can_unprotect?(user)).to eq false
        expect(subject.can_unprotect?(master)).to eq true
        expect(subject.can_unprotect?(admin)).to eq true
      end
    end

    context 'with access level set to ADMIN' do
      before do
        subject.unprotect_access_levels.create!(access_level: Gitlab::Access::ADMIN)
      end

      it 'prevents access to masters' do
        expect(subject.can_unprotect?(master)).to eq false
      end

      it 'grants access to admins' do
        expect(subject.can_unprotect?(admin)).to eq true
      end
    end

    context 'multiple access levels' do
      before do
        subject.unprotect_access_levels.create!(user: master)
        subject.unprotect_access_levels.create!(user: user)
      end

      it 'grants access if any grant access' do
        expect(subject.can_unprotect?(user)).to eq true
      end
    end
  end
end
