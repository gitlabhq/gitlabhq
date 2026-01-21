# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Security::ScanFeatureType, feature_category: :security_asset_inventories do
  include GraphqlHelpers

  it 'has expected fields' do
    expect(described_class).to have_graphql_fields(
      :available,
      :can_enable_by_merge_request,
      :configuration_path,
      :configured,
      :meta_info_path,
      :on_demand_available,
      :security_features,
      :type
    )
  end

  describe '#security_features' do
    let_it_be(:object_with_features) { { security_features: { name: 'SAST', type: 'sast' } } }
    let_it_be(:object_without_features) { { security_features: {} } }
    let_it_be(:object_with_nil_features) { { security_features: nil } }
    let_it_be(:context) { query_context(user: User.new) }

    it 'returns security_features when present' do
      type_instance = described_class.authorized_new(object_with_features, context)
      expect(type_instance.security_features).to eq({ name: 'SAST', type: 'sast' })
    end

    it 'returns nil when security_features is an empty hash' do
      type_instance = described_class.authorized_new(object_without_features, context)
      expect(type_instance.security_features).to be_nil
    end

    it 'returns nil when security_features is nil' do
      type_instance = described_class.authorized_new(object_with_nil_features, context)
      expect(type_instance.security_features).to be_nil
    end
  end
end
