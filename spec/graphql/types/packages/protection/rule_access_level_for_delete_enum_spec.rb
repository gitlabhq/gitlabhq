# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackagesProtectionRuleAccessLevelForDelete'], feature_category: :package_registry do
  it 'exposes all options' do
    expect(described_class.values.keys).to match_array(%w[OWNER ADMIN])
  end
end
