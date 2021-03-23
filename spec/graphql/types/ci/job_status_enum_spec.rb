# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobStatus'] do
  it 'exposes all job status values' do
    expect(described_class.values.values).to contain_exactly(
      *::Ci::HasStatus::AVAILABLE_STATUSES.map do |status|
        have_attributes(value: status, graphql_name: status.upcase)
      end
    )
  end
end
