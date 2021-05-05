# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Kas'] do
  specify { expect(described_class.graphql_name).to eq('Kas') }
  specify { expect(described_class).to require_graphql_authorizations(:read_instance_metadata) }
end
