# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SecurityReportTypeEnum'] do
  it 'exposes all security report types' do
    expect(described_class.values.keys).to match_array(Enums::Security.analyzer_types.keys.map(&:to_s).map(&:upcase))
  end
end
