# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SecurityReportTypeEnum'] do
  it 'exposes all security report types' do
    expect(described_class.values.keys).to contain_exactly(
      *::Security::SecurityJobsFinder.allowed_job_types.map(&:to_s).map(&:upcase)
    )
  end
end
