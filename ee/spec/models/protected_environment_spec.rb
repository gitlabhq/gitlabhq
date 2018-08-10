# frozen_string_literal: true
require 'spec_helper'

describe ProtectedEnvironment do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:deploy_access_levels) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:deploy_access_levels) }
  end

  describe '#accessible_to?' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
    let(:user) { create(:user) }

    subject { protected_environment.accessible_to?(user) }

    context 'when user is admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be_truthy }
    end

    context 'when access has been granted to user' do
      before do
        create_deploy_access_level(user: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when specific access has been assigned to a group' do
      let(:group) { create(:group) }

      before do
        create_deploy_access_level(group: group)
      end

      it 'should allow members of the group' do
        group.add_developer(user)

        expect(subject).to be_truthy
      end

      it 'should reject non-members of the group' do
        expect(subject).to be_falsy
      end
    end

    context 'when access has been granted to maintainers' do
      before do
        create_deploy_access_level(access_level: Gitlab::Access::MAINTAINER)
      end

      it 'should allow maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_truthy
      end

      it 'should reject developers' do
        project.add_developer(user)

        expect(subject).to be_falsy
      end
    end

    context 'when access has been granted to developers' do
      before do
        create_deploy_access_level(access_level: Gitlab::Access::DEVELOPER)
      end

      it 'should allow maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_truthy
      end

      it 'should allow developers' do
        project.add_developer(user)

        expect(subject).to be_truthy
      end
    end
  end

  def create_deploy_access_level(**opts)
    protected_environment.deploy_access_levels.create(**opts)
  end
end
