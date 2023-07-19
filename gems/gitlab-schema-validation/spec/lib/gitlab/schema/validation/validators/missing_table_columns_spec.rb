# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::MissingTableColumns, feature_category: :database do
  include_examples 'table validators', described_class, ['missing_table_columns']
end
