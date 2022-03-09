# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistryHelper do
  describe '#container_registry_expiration_policies_throttling?' do
    subject { helper.container_registry_expiration_policies_throttling? }

    it { is_expected.to eq(true) }

    context 'with container_registry_expiration_policies_throttling disabled' do
      before do
        stub_feature_flags(container_registry_expiration_policies_throttling: false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
