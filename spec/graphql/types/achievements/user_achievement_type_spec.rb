# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserAchievement'], feature_category: :user_profile do
  include GraphqlHelpers

  let(:fields) do
    %w[
      id
      achievement
      user
      awarded_by_user
      revoked_by_user
      created_at
      updated_at
      revoked_at
      priority
      show_on_profile
    ]
  end

  it { expect(described_class.graphql_name).to eq('UserAchievement') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_user_achievement) }
end
