# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/ci/job_artifacts_deleted_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Ci::JobArtifactsDeletedEvent, feature_category: :continuous_integration do
  it_behaves_like 'an event with schema',
    valid_data: { job_ids: [1, 2, 3] },
    missing_required: %i[job_ids],
    invalid_types: { job_ids: 'not_an_array' }

  describe '#schema' do
    context 'with invalid array item types' do
      it 'raises an error when job_ids contains non-integers' do
        expect { described_class.new(data: { job_ids: ['not_an_integer'] }) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end
    end
  end
end
