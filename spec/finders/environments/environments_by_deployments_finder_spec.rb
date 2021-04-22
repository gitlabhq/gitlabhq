# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::EnvironmentsByDeploymentsFinder do
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:environment) { create(:environment, :available, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'tagged deployment' do
      let(:environment_two) { create(:environment, project: project) }
      # Environments need to include commits, so rewind two commits to fit
      let(:commit) { project.commit('HEAD~2') }

      before do
        create(:deployment, :success, environment: environment, ref: 'v1.0.0', tag: true, sha: project.commit.id)
        create(:deployment, :success, environment: environment_two, ref: 'v1.1.0', tag: true, sha: project.commit('HEAD~1').id)
      end

      it 'returns environment when with_tags is set' do
        expect(described_class.new(project, user, ref: 'master', commit: commit, with_tags: true).execute)
          .to contain_exactly(environment, environment_two)
      end

      it 'does not return environment when no with_tags is set' do
        expect(described_class.new(project, user, ref: 'master', commit: commit).execute)
          .to be_empty
      end

      it 'does not return environment when commit is not part of deployment' do
        expect(described_class.new(project, user, ref: 'master', commit: project.commit('feature')).execute)
          .to be_empty
      end

      # We expect two Gitaly calls: FindCommit, CommitIsAncestor
      # This tests to ensure we don't call one CommitIsAncestor per environment
      it 'only calls Gitaly twice when multiple environments are present', :request_store do
        expect do
          result = described_class.new(project, user, ref: 'master', commit: commit, with_tags: true, find_latest: true).execute

          expect(result).to contain_exactly(environment_two)
        end.to change { Gitlab::GitalyClient.get_request_count }.by(2)
      end
    end

    context 'branch deployment' do
      before do
        create(:deployment, :success, environment: environment, ref: 'master', sha: project.commit.id)
      end

      it 'returns environment when ref is set' do
        expect(described_class.new(project, user, ref: 'master', commit: project.commit).execute)
          .to contain_exactly(environment)
      end

      it 'does not environment when ref is different' do
        expect(described_class.new(project, user, ref: 'feature', commit: project.commit).execute)
          .to be_empty
      end

      it 'does not return environment when commit is not part of deployment' do
        expect(described_class.new(project, user, ref: 'master', commit: project.commit('feature')).execute)
          .to be_empty
      end

      it 'returns environment when commit constraint is not set' do
        expect(described_class.new(project, user, ref: 'master').execute)
          .to contain_exactly(environment)
      end
    end

    context 'commit deployment' do
      before do
        create(:deployment, :success, environment: environment, ref: 'master', sha: project.commit.id)
      end

      it 'returns environment' do
        expect(described_class.new(project, user, commit: project.commit).execute)
          .to contain_exactly(environment)
      end
    end

    context 'recently updated' do
      context 'when last deployment to environment is the most recent one' do
        before do
          create(:deployment, :success, environment: environment, ref: 'feature')
        end

        it 'finds recently updated environment' do
          expect(described_class.new(project, user, ref: 'feature', recently_updated: true).execute)
            .to contain_exactly(environment)
        end
      end

      context 'when last deployment to environment is not the most recent' do
        before do
          create(:deployment, :success, environment: environment, ref: 'feature')
          create(:deployment, :success, environment: environment, ref: 'master')
        end

        it 'does not find environment' do
          expect(described_class.new(project, user, ref: 'feature', recently_updated: true).execute)
            .to be_empty
        end
      end

      context 'when there are two environments that deploy to the same branch' do
        let(:second_environment) { create(:environment, project: project) }

        before do
          create(:deployment, :success, environment: environment, ref: 'feature')
          create(:deployment, :success, environment: second_environment, ref: 'feature')
        end

        it 'finds both environments' do
          expect(described_class.new(project, user, ref: 'feature', recently_updated: true).execute)
            .to contain_exactly(environment, second_environment)
        end
      end
    end
  end
end
