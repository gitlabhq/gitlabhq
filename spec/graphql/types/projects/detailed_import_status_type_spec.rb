# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DetailedImportStatus'], feature_category: :importers do
  include GraphqlHelpers

  let(:fields) do
    %w[
      id
      status
      url
      last_error
      last_update_at
      last_update_started_at
      last_successful_update_at
    ]
  end

  it { expect(described_class.graphql_name).to eq('DetailedImportStatus') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_project) }
end
