# frozen_string_literal: true

require 'spec_helper'

describe ClustersHelper do
  describe '#has_rbac_enabled?' do
    context 'when kubernetes platform has been created' do
      let(:platform_kubernetes) { build_stubbed(:cluster_platform_kubernetes) }
      let(:cluster) { build_stubbed(:cluster, :provided_by_gcp, platform_kubernetes: platform_kubernetes) }

      it 'returns kubernetes platform value' do
        expect(helper.has_rbac_enabled?(cluster)).to be_truthy
      end
    end

    context 'when kubernetes platform has not been created yet' do
      let(:cluster) { build_stubbed(:cluster, :providing_by_gcp) }

      it 'delegates to cluster provider' do
        expect(helper.has_rbac_enabled?(cluster)).to be_truthy
      end

      context 'when ABAC cluster is created' do
        let(:provider) { build_stubbed(:cluster_provider_gcp, :abac_enabled) }
        let(:cluster) { build_stubbed(:cluster, :providing_by_gcp, provider_gcp: provider) }

        it 'delegates to cluster provider' do
          expect(helper.has_rbac_enabled?(cluster)).to be_falsy
        end
      end
    end
  end
end
