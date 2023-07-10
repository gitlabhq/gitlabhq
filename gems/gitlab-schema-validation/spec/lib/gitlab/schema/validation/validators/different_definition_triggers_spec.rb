# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::DifferentDefinitionTriggers,
  feature_category: :database do
  include_examples 'trigger validators', described_class, ['wrong_trigger']
end
