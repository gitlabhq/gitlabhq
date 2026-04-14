# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformStateProtectionRuleAccessLevel'],
  feature_category: :infrastructure_as_code do
  it 'exposes all options' do
    expect(described_class.values.keys).to match_array(%w[DEVELOPER MAINTAINER OWNER ADMIN])
  end
end
