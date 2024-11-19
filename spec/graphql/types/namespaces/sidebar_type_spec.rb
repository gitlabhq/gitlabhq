# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NamespaceSidebar'], feature_category: :navigation do
  let(:fields) do
    %i[open_issues_count open_merge_requests_count]
  end

  specify { expect(described_class.graphql_name).to eq('NamespaceSidebar') }

  specify { expect(described_class).to have_graphql_fields(fields).at_least }
end
