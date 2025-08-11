# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Projects::ProjectInterface, feature_category: :groups_and_projects do
  it 'has the correct name' do
    expect(described_class.graphql_name).to eq('ProjectInterface')
  end

  describe ".resolve_type" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    subject { described_class.resolve_type(project, { current_user: user }) }

    it { is_expected.to eq Types::ProjectType }
  end
end
