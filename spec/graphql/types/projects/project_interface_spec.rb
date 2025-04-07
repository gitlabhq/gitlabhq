# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Projects::ProjectInterface, feature_category: :groups_and_projects do
  it 'has the correct name' do
    expect(described_class.graphql_name).to eq('ProjectInterface')
  end

  it 'has the expected fields' do
    expected_fields = %w[id name name_with_namespace description web_url avatar_url]

    expect(described_class.own_fields.size).to eq(expected_fields.size)
    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe ".resolve_type" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    subject { described_class.resolve_type(project, { current_user: user }) }

    it { is_expected.to eq Types::ProjectType }
  end
end
