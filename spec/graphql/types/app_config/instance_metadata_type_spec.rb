# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Metadata'], feature_category: :api do
  specify { expect(described_class.graphql_name).to eq('Metadata') }
  specify { expect(described_class).to require_graphql_authorizations(:read_instance_metadata) }
end
