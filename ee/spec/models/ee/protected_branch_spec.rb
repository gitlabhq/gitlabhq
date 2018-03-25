require 'spec_helper'

describe ProtectedBranch do
  subject { create(:protected_branch) }

  let(:project) { subject.project }

  describe '#can_unprotect?' do
    let(:user) { create(:user) }
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
