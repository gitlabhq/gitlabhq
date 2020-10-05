# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Graphql Field feature flags' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let(:feature_flag) { 'test_feature' }
  let(:test_object) { double(name: 'My name') }
  let(:query_string) { '{ item { name } }' }
  let(:result) { execute_query(query_type)['data'] }

  before do
    skip_feature_flags_yaml_validation
  end

  subject { result }

  describe 'Feature flagged field' do
    let(:type) { type_factory }

    let(:query_type) do
      query_factory do |query|
        query.field :item, type, null: true, feature_flag: feature_flag, resolve: ->(obj, args, ctx) { test_object }
      end
    end

    it 'returns the value when feature is enabled' do
      expect(subject['item']).to eq('name' => test_object.name)
    end

    it 'returns nil when the feature is disabled' do
      stub_feature_flags(feature_flag => false)

      expect(subject).to be_nil
    end
  end
end
