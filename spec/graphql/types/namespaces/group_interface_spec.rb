# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Namespaces::GroupInterface, feature_category: :groups_and_projects do
  it 'has the correct name' do
    expect(described_class.graphql_name).to eq('GroupInterface')
  end

  it 'has the expected fields' do
    expected_fields = %w[id name full_name full_path web_url avatar_url user_permissions]

    expect(described_class.own_fields.keys.map(&:underscore)).to match_array(expected_fields)
  end

  describe ".resolve_type" do
    let_it_be(:user) { build(:user) }
    let_it_be(:group) { build(:group) }

    subject { described_class.resolve_type(group, { current_user: user }) }

    it { is_expected.to eq Types::GroupType }
  end
end
