# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::ExtraIndexes do
  include_examples 'index validators', described_class, ['extra_index']
end
