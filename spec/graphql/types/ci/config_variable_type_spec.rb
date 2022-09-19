# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiConfigVariable'] do
  specify { expect(described_class).to have_graphql_fields(:key, :description, :value).at_least }
end
