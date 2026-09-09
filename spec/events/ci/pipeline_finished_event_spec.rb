# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/ci/pipeline_finished_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Ci::PipelineFinishedEvent, feature_category: :continuous_integration do
  it_behaves_like 'an event with schema',
    valid_data: { pipeline_id: 1, status: 'success', source: 'push', partition_id: 100, source_ref: 'master' },
    missing_required: %i[pipeline_id status source partition_id],
    invalid_types: {
      pipeline_id: 'not_an_integer',
      status: 123,
      source: 123,
      partition_id: 'not_an_integer',
      source_ref: 123
    }

  describe 'optional source_ref' do
    let(:data) { { pipeline_id: 1, status: 'success', source: 'push', partition_id: 100 } }

    it 'initializes without error when source_ref is absent' do
      expect { described_class.new(data: data) }.not_to raise_error
    end

    it 'initializes without error when source_ref is nil' do
      expect { described_class.new(data: data.merge(source_ref: nil)) }.not_to raise_error
    end
  end
end
