# frozen_string_literal: true
require 'spec_helper'

describe ProtectedEnvironments::UpdateService, '#execute' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }
  let(:protected_environment) { create(:protected_environment, project: project) }
  let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

  let(:params) do
    {
      deploy_access_levels_attributes: [
        { id: deploy_access_level.id, access_level: Gitlab::Access::DEVELOPER },
        { access_level: maintainer_access }
      ]
    }
  end

  subject { described_class.new(project, user, params).execute(protected_environment) }

  before do
    deploy_access_level
  end

  context 'with valid params' do
    it { is_expected.to be_truthy }

    it 'should change update the deploy access levels' do
      expect do
        subject
      end.to change { ProtectedEnvironment::DeployAccessLevel.count }.from(1).to(2)
    end
  end

  context 'with invalid params' do
    let(:maintainer_access) { 0 }

    it { is_expected.to be_falsy }

    it 'should not update the deploy access levels' do
      expect do
        subject
      end.not_to change { ProtectedEnvironment::DeployAccessLevel.count }
    end
  end
end
