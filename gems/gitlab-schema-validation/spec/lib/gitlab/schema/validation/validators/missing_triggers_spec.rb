# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::MissingTriggers, feature_category: :database do
  missing_triggers = %w[missing_trigger_1 projects_loose_fk_trigger]

  include_examples 'trigger validators', described_class, missing_triggers
end
