# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerProtectionAccessLevel'], feature_category: :container_registry do
  specify { expect(described_class.graphql_name).to eq('ContainerProtectionAccessLevel') }

  specify { expect(described_class.description).to be_present }

  describe 'minimum_access_level_for_push', unless: Gitlab.ee? do
    subject { described_class.fields['minimumAccessLevelForPush'] }

    it { is_expected.to have_non_null_graphql_type(Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum) }
  end

  describe 'minimum_access_level_for_delete', unless: Gitlab.ee? do
    subject { described_class.fields['minimumAccessLevelForDelete'] }

    it { is_expected.to have_non_null_graphql_type(Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum) }
  end
end
