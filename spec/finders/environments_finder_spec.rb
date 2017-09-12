require 'spec_helper'

describe EnvironmentsFinder do
  describe '#execute' do
    let(:project) { create(:project, :repository) }
    let(:user) { project.creator }
    let(:environment) { create(:environment, project: project) }

    before do
      project.add_master(user)
    end

    context 'tagged deployment' do
      before do
        create(:deployment, environment: environment, ref: 'v1.1.0', tag: true, sha: project.commit.id)
      end

      it 'returns environment when with_tags is set' do
        expect(described_class.new(project, user, ref: 'master', commit: project.commit, with_tags: true).execute)
          .to contain_exactly(environment)
      end

      it 'does not return environment when no with_tags is set' do
        expect(described_class.new(project, user, ref: 'master', commit: project.commit).execute)
          .to be_empty
      end

      it 'does not return environment when commit is not part of deployment' do
        expect(described_class.new(project, user, ref: 'master', commit: project.commit('feature')).execute)
          .to be_empty
      end
    end

    context 'branch deployment' do
      before do
        create(:deployment, environment: environment, ref: 'master', sha: project.commit.id)
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
        create(:deployment, environment: environment, ref: 'master', sha: project.commit.id)
      end

      it 'returns environment' do
        expect(described_class.new(project, user, commit: project.commit).execute)
          .to contain_exactly(environment)
      end
    end

    context 'recently updated' do
      context 'when last deployment to environment is the most recent one' do
        before do
          create(:deployment, environment: environment, ref: 'feature')
        end

        it 'finds recently updated environment' do
          expect(described_class.new(project, user, ref: 'feature', recently_updated: true).execute)
            .to contain_exactly(environment)
        end
      end

      context 'when last deployment to environment is not the most recent' do
        before do
          create(:deployment, environment: environment, ref: 'feature')
          create(:deployment, environment: environment, ref: 'master')
        end

        it 'does not find environment' do
          expect(described_class.new(project, user, ref: 'feature', recently_updated: true).execute)
            .to be_empty
        end
      end

      context 'when there are two environments that deploy to the same branch' do
        let(:second_environment) { create(:environment, project: project) }

        before do
          create(:deployment, environment: environment, ref: 'feature')
          create(:deployment, environment: second_environment, ref: 'feature')
        end

        it 'finds both environments' do
          expect(described_class.new(project, user, ref: 'feature', recently_updated: true).execute)
            .to contain_exactly(environment, second_environment)
        end
      end
    end
  end
end
