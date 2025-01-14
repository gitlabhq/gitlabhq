# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerProtectionTagRuleAccessLevel'], feature_category: :container_registry do
  it 'exposes all options' do
    expect(described_class.values.keys).to match_array(%w[MAINTAINER OWNER ADMIN])
  end
end
