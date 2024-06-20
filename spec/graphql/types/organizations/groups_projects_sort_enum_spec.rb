# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationGroupProjectSort'], feature_category: :groups_and_projects do
  let_it_be(:fields) do
    %w[
      NAME_ASC NAME_DESC
      CREATED_ASC CREATED_DESC
      UPDATED_ASC UPDATED_DESC
      created_asc created_desc
      updated_asc updated_desc
    ]
  end

  specify { expect(described_class.graphql_name).to eq('OrganizationGroupProjectSort') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
