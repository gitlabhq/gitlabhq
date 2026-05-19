# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Organization'], feature_category: :organization do
  let_it_be(:expected_fields) do
    %w[avatar_url description description_html groups id name organization_users path root_path projects state
      web_url visibility web_path workItemTypes]
  end

  specify { expect(described_class.graphql_name).to eq('Organization') }
  specify { expect(described_class).to include_graphql_fields(*expected_fields) }
end
