# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../app/events/gitlab/feature_flags/feature_flag_modified_event'
require_relative '../../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Gitlab::FeatureFlags::FeatureFlagModifiedEvent, feature_category: :feature_flags do
  it_behaves_like 'an event with schema',
    valid_data: {
      feature_key: 'my_feature_flag',
      operation: 'enabled_actor',
      actor: 'User:123',
      state: 'conditional'
    },
    missing_required: %i[feature_key operation state],
    invalid_types: {
      feature_key: 123,
      operation: 123,
      state: 123
    }

  describe '#schema' do
    context 'with global enable operation' do
      it 'initializes without error' do
        expect do
          described_class.new(data: {
            feature_key: 'my_flag',
            operation: 'enabled_globally',
            actor: nil,
            state: 'on'
          })
        end.not_to raise_error
      end
    end

    context 'with actor enable operation' do
      it 'initializes without error' do
        expect do
          described_class.new(data: {
            feature_key: 'my_flag',
            operation: 'enabled_actor',
            actor: 'User:123',
            state: 'conditional'
          })
        end.not_to raise_error
      end
    end

    context 'with global disable operation' do
      it 'initializes without error' do
        expect do
          described_class.new(data: {
            feature_key: 'my_flag',
            operation: 'disabled_globally',
            actor: nil,
            state: 'off'
          })
        end.not_to raise_error
      end
    end

    context 'with actor disable operation' do
      it 'initializes without error' do
        expect do
          described_class.new(data: {
            feature_key: 'my_flag',
            operation: 'disabled_actor',
            actor: 'User:456',
            state: 'conditional'
          })
        end.not_to raise_error
      end
    end

    context 'with different actor types' do
      it 'initializes with Group actor' do
        expect do
          described_class.new(data: {
            feature_key: 'my_flag',
            operation: 'enabled_actor',
            actor: 'Group:789',
            state: 'conditional'
          })
        end.not_to raise_error
      end

      it 'initializes with Project actor' do
        expect do
          described_class.new(data: {
            feature_key: 'my_flag',
            operation: 'enabled_actor',
            actor: 'Project:101',
            state: 'conditional'
          })
        end.not_to raise_error
      end
    end
  end
end
