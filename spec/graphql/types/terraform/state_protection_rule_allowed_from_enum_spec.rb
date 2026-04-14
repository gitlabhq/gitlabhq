# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformStateProtectionRuleAllowedFrom'],
  feature_category: :infrastructure_as_code do
  it 'exposes all options' do
    expect(described_class.values.keys).to match_array(%w[ANYWHERE CI_ONLY CI_ON_PROTECTED_BRANCH_ONLY])
  end
end
