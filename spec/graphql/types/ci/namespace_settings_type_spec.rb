# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::NamespaceSettingsType, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:namespace_settings) { build(:namespace_settings, namespace: namespace) }

  specify { expect(described_class.graphql_name).to eq('CiCdSettings') }

  it 'requires authorization' do
    expect(described_class).to require_graphql_authorizations(:maintainer_access)
  end

  it 'exposes the expected fields' do
    expect(described_class).to have_graphql_field(:pipeline_variables_default_role)
  end
end
