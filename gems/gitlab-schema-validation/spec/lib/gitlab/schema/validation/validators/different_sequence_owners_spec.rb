# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::DifferentSequenceOwners, feature_category: :database do
  wrong_sequence_owners = %w[
    public.zoekt_repositories_id_seq
  ]
  expected_details = [
    {
      current_owner: 'public.wrong_table.id',
      expected_owner: "public.zoekt_repositories.id"
    }
  ]

  include_examples 'sequence validators', described_class, wrong_sequence_owners, expected_details
end
