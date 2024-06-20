# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationGroupProjectDisplay'], feature_category: :groups_and_projects do
  let_it_be(:fields) do
    %w[PROJECTS GROUPS]
  end

  specify { expect(described_class.graphql_name).to eq('OrganizationGroupProjectDisplay') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
