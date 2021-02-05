# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistryHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#container_registry_expiration_policies_throttling?' do
    subject { helper.container_registry_expiration_policies_throttling? }

    where(:feature_flag_enabled, :client_support, :expected_result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        stub_feature_flags(container_registry_expiration_policies_throttling: feature_flag_enabled)
        allow(ContainerRegistry::Client).to receive(:supports_tag_delete?).and_return(client_support)
      end

      it { is_expected.to eq(expected_result) }
    end
  end
end
