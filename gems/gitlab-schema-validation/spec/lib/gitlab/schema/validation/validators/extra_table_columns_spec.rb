# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::ExtraTableColumns, feature_category: :database do
  include_examples 'table validators', described_class, ['extra_table_columns']
end
