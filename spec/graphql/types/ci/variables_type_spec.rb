# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiVariable'] do
  it 'contains attributes related to CI variables' do
    expect(described_class).to have_graphql_fields(
      :id, :key, :value, :variable_type, :protected, :masked, :raw
    )
  end
end
