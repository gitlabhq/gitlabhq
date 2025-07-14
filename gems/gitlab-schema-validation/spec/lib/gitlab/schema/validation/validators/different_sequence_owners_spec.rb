# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::DifferentSequenceOwners, feature_category: :database do
  wrong_sequence_owners = %w[
    public.zoekt_repositories_id_seq
  ]

  include_examples 'sequence validators', described_class, wrong_sequence_owners
end
