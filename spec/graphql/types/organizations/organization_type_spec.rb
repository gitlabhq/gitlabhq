# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Organization'], feature_category: :cell do
  let(:expected_fields) { %w[avatar_url description description_html groups id name organization_users path web_url] }

  specify { expect(described_class.graphql_name).to eq('Organization') }
  specify { expect(described_class).to require_graphql_authorizations(:read_organization) }
  specify { expect(described_class).to have_graphql_fields(*expected_fields) }
end
