# frozen_string_literal: true
require 'spec_helper'

describe ProtectedEnvironments::DestroyService, '#execute' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:protected_environment) { create(:protected_environment, project: project) }
  let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

  subject { described_class.new(project, user).execute(protected_environment) }

  context 'when the Protected Environment is deleted' do
    it { is_expected.to be_truthy }

    it 'should delete the requested ProtectedEnvironment' do
      expect do
        subject
      end.to change { ProtectedEnvironment.count }.from(1).to(0)
    end

    it 'should delete the related DeployAccessLevel' do
      expect do
        subject
      end.to change { ProtectedEnvironment::DeployAccessLevel.count }.from(1).to(0)
    end
  end

  context 'when the Protected Environment can not be deleted' do
    before do
      allow(protected_environment).to receive(:destroy).and_return(false)
    end

    it { is_expected.to be_falsy }
  end
end
