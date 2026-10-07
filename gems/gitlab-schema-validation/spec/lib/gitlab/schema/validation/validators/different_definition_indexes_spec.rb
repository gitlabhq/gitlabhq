# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::DifferentDefinitionIndexes do
  different_indexes = %w[
    wrong_index
    swapped_index_1
    swapped_index_2
    wrong_partition_index
    redefined_partition_index
  ]

  include_examples 'index validators', described_class, different_indexes
end
