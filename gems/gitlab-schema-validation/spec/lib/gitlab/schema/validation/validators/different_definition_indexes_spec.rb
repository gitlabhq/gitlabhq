# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::DifferentDefinitionIndexes do
  include_examples 'index validators', described_class, ['wrong_index']
end
