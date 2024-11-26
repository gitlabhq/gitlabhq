# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AccessLevelEnum'] do
  specify { expect(described_class.graphql_name).to eq('AccessLevelEnum') }

  it 'exposes all the existing access levels' do
    expect(described_class.values.keys)
      .to include(*%w[NO_ACCESS MINIMAL_ACCESS GUEST PLANNER REPORTER DEVELOPER MAINTAINER OWNER])
  end
end
