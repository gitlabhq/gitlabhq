# frozen_string_literal: true
require 'spec_helper'

describe Ci::EnqueueBuildService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, project: project, name: 'production') }
  let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
  let(:ci_build) { create(:ci_build, :created, environment: environment.name, user: user) }

  subject { described_class.new(project, user).execute(ci_build) }

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?)
      .with(:protected_environments).and_return(feature_available)

    protected_environment
  end

  context 'when related to a protected environment' do
    context 'when Protected Environments feature is not available on project' do
      let(:feature_available) { false }

      it 'enqueues the build' do
        subject

        expect(ci_build.pending?).to be_truthy
      end
    end

    context 'when Protected Environments feature is available on project' do
      let(:feature_available) { true }

      context 'when user does not have access to the environment' do
        it 'should fail the build' do
          subject

          expect(ci_build.failed?).to be_truthy
          expect(ci_build.failure_reason).to eq('protected_environment_failure')
        end
      end

      context 'when user has access to the environment' do
        before do
          protected_environment.deploy_access_levels.create(user: user)
        end

        it 'enqueues the build' do
          subject

          expect(ci_build.pending?).to be_truthy
        end
      end
    end
  end
end
