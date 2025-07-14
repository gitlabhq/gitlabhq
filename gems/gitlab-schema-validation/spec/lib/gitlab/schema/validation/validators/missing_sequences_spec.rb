# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::MissingSequences, feature_category: :database do
  missing_sequences = %w[
    public.missing_sequence
    public.abuse_events_id_seq
  ]

  include_examples 'sequence validators', described_class, missing_sequences
end
