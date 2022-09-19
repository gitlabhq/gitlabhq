# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiVariable'] do
  specify do
    expect(described_class).to have_graphql_fields(
      :id, :key, :raw, :value, :variable_type
    ).at_least
  end
end
