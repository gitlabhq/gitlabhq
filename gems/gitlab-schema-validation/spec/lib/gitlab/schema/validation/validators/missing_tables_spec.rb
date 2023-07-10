# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::MissingTables, feature_category: :database do
  missing_tables = %w[ci_project_mirrors missing_table operations_user_lists test_table]

  include_examples 'table validators', described_class, missing_tables
end
