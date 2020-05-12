# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Milestone'] do
  specify { expect(described_class.graphql_name).to eq('Milestone') }

  specify { expect(described_class).to require_graphql_authorizations(:read_milestone) }
end
