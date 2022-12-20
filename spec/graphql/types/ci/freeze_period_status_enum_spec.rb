# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiFreezePeriodStatus'], feature_category: :release_orchestration do
  it 'exposes all freeze period statuses' do
    expect(described_class.values.keys).to contain_exactly(*%w[ACTIVE INACTIVE])
  end
end
