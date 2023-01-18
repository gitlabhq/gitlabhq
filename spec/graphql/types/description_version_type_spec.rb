# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DescriptionVersion'], feature_category: :team_planning do
  it { expect(described_class).to have_graphql_field(:id) }
  it { expect(described_class).to have_graphql_field(:description) }

  specify { expect(described_class).to require_graphql_authorizations(:read_issuable) }
end
