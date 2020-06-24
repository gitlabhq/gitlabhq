# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['JiraProject'] do
  it { expect(described_class.graphql_name).to eq('JiraProject') }

  it 'has basic expected fields' do
    expect(described_class).to have_graphql_fields(:key, :project_id, :name)
  end
end
