require 'rails_helper'

describe EE::DeploymentPlatform do
  describe '#deployment_platform' do
    let(:project) { create(:project) }

    shared_examples 'matching environment scope' do
      context 'when multiple clusters license is available' do
        before do
          stub_licensed_features(multiple_clusters: true)
        end

        it 'returns environment specific cluster' do
          is_expected.to eq(cluster.platform_kubernetes)
        end
      end

      context 'when multiple clusters licence is unavailable' do
        before do
          stub_licensed_features(multiple_clusters: false)
        end

        it 'returns a kubernetes platform' do
          is_expected.to be_kind_of(Clusters::Platforms::Kubernetes)
        end
      end
    end

    shared_examples 'not matching environment scope' do
      context 'when multiple clusters license is available' do
        before do
          stub_licensed_features(multiple_clusters: true)
        end

        it 'returns default cluster' do
          is_expected.to eq(default_cluster.platform_kubernetes)
        end
      end

      context 'when multiple clusters license is unavailable' do
        before do
          stub_licensed_features(multiple_clusters: false)
        end

        it 'returns a kubernetes platform' do
          is_expected.to be_kind_of(Clusters::Platforms::Kubernetes)
        end
      end
    end

    context 'when environment is specified' do
      let!(:default_cluster) { create(:cluster, :provided_by_user, projects: [project], environment_scope: '*') }
      let!(:cluster) { create(:cluster, :provided_by_user, environment_scope: 'review/*', projects: [project]) }

      let(:environment) { 'review/name' }

      subject { project.deployment_platform(environment: environment) }

      context 'when environment scope is exactly matched' do
        before do
          cluster.update!(environment_scope: 'review/name')
        end

        it_behaves_like 'matching environment scope'
      end

      context 'when environment scope is matched by wildcard' do
        before do
          cluster.update!(environment_scope: 'review/*')
        end

        it_behaves_like 'matching environment scope'
      end

      context 'when environment scope does not match' do
        before do
          cluster.update!(environment_scope: 'review/*/special')
        end

        it_behaves_like 'not matching environment scope'
      end

      context 'when environment scope has _' do
        before do
          stub_licensed_features(multiple_clusters: true)
        end

        it 'does not treat it as wildcard' do
          cluster.update!(environment_scope: 'foo_bar/*')

          is_expected.to eq(default_cluster.platform_kubernetes)
        end

        context 'when environment name contains an underscore' do
          let(:environment) { 'foo_bar/test' }

          it 'matches literally for _' do
            cluster.update!(environment_scope: 'foo_bar/*')

            is_expected.to eq(cluster.platform_kubernetes)
          end
        end
      end

      # The environment name and scope cannot have % at the moment,
      # but we're considering relaxing it and we should also make sure
      # it doesn't break in case some data sneaked in somehow as we're
      # not checking this integrity in database level.
      context 'when environment scope has %' do
        before do
          stub_licensed_features(multiple_clusters: true)
        end

        it 'does not treat it as wildcard' do
          cluster.update_attribute(:environment_scope, '*%*')

          is_expected.to eq(default_cluster.platform_kubernetes)
        end

        context 'when environment name contains a percent char' do
          let(:environment) { 'foo%bar/test' }

          it 'matches literally for %' do
            cluster.update_attribute(:environment_scope, 'foo%bar/*')

            is_expected.to eq(cluster.platform_kubernetes)
          end
        end
      end

      context 'when perfectly matched cluster exists' do
        let!(:perfectly_matched_cluster) { create(:cluster, :provided_by_user, projects: [project], environment_scope: 'review/name') }

        before do
          stub_licensed_features(multiple_clusters: true)
        end

        it 'returns perfectly matched cluster as highest precedence' do
          is_expected.to eq(perfectly_matched_cluster.platform_kubernetes)
        end
      end
    end

    context 'with multiple clusters and multiple environments' do
      let!(:cluster_1) { create(:cluster, :provided_by_user, projects: [project], environment_scope: 'staging/*') }
      let!(:cluster_2) { create(:cluster, :provided_by_user, projects: [project], environment_scope: 'test/*') }

      let(:environment_1) { 'staging/name' }
      let(:environment_2) { 'test/name' }

      before do
        stub_licensed_features(multiple_clusters: true)
      end

      it 'should return the appropriate cluster' do
        expect(project.deployment_platform(environment: environment_1)).to eq(cluster_1.platform_kubernetes)
        expect(project.deployment_platform(environment: environment_2)).to eq(cluster_2.platform_kubernetes)
      end
    end
  end
end
