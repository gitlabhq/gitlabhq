# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['JiraService'] do
  specify { expect(described_class.graphql_name).to eq('JiraService') }

  it 'has basic expected fields' do
    expect(described_class).to have_graphql_fields(:type, :active, :projects, :service_type)
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_project) }
end
