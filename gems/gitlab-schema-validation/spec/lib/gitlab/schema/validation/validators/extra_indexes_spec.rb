# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::ExtraIndexes, feature_category: :database do
  extra_indexes = %w[
    extra_index
    renamed_index_new
    duplicated_index_copy
    extra_partition_index
    manual_partition_index
    bigint_idx_manual
    relocated_partition_index
    renamed_partition_index
  ]

  include_examples 'index validators', described_class, extra_indexes
end
