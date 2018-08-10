# frozen_string_literal: true
require 'spec_helper'

describe ProtectedEnvironment::DeployAccessLevel do
  describe 'associations' do
    it { is_expected.to belong_to(:protected_environment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_level) }
  end

  describe '#check_access' do
    let(:project) { create(:project) }
    let(:protected_environment) { create(:protected_environment, project: project) }
    let(:user) { create(:user) }

    subject { deploy_access_level.check_access(user) }

    describe 'admin access' do
      let(:user) { create(:user, :admin) }

      context 'when admin user does have specific access' do
        let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment, user: user) }

        it { is_expected.to be_truthy }
      end

      context 'when admin user does not have specific access' do
        let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment) }

        it { is_expected.to be_truthy }
      end
    end

    describe 'user access' do
      context 'when specific access has been assigned to a user' do
        let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment, user: user) }

        it { is_expected.to be_truthy }
      end

      context 'when no permissions have been given to a user' do
        let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment) }

        it { is_expected.to be_falsy }
      end
    end

    describe 'group access' do
      let(:group) { create(:group, projects: [project]) }

      context 'when specific access has been assigned to a group' do
        let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment, group: group) }

        before do
          group.add_reporter(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when no permissions have been given to a group' do
        let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment) }

        before do
          group.add_reporter(user)
        end

        it { is_expected.to be_falsy }
      end
    end

    describe 'access level' do
      let(:developer_access) { Gitlab::Access::DEVELOPER }
      let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment, access_level: developer_access) }

      context 'when user is project member above the permitted access level' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when user is project member below the permitted access level' do
        before do
          project.add_reporter(user)
        end

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#humanize' do
    let(:protected_environment) { create(:protected_environment) }

    subject { deploy_access_level.humanize }

    context 'when is related to a user' do
      let(:user) { create(:user) }
      let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment, user: user) }

      it { is_expected.to eq(user.name) }
    end

    context 'when is related to a group' do
      let(:group) { create(:group) }
      let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment, group: group) }

      it { is_expected.to eq(group.name) }
    end

    context 'when is set to have a role' do
      let(:deploy_access_level) { create(:protected_environment_deploy_access_level, protected_environment: protected_environment, access_level: access_level) }

      context 'for developer access' do
        let(:access_level) { Gitlab::Access::DEVELOPER }

        it { is_expected.to eq('Developers + Maintainers') }
      end

      context 'for maintainer access' do
        let(:access_level) { Gitlab::Access::MAINTAINER }

        it { is_expected.to eq('Maintainers') }
      end
    end
  end
end
