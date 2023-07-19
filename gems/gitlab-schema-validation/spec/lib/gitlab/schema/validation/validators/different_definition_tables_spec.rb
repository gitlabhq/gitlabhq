# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::DifferentDefinitionTables, feature_category: :database do
  include_examples 'table validators', described_class, ['wrong_table']
end
