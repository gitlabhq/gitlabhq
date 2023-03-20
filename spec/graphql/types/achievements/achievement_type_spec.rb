# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Achievement'], feature_category: :user_profile do
  include GraphqlHelpers

  let(:fields) do
    %w[
      id
      namespace
      name
      avatar_url
      description
      created_at
      updated_at
      user_achievements
    ]
  end

  it { expect(described_class.graphql_name).to eq('Achievement') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_achievement) }

  describe '#avatar_url' do
    let(:object) { instance_double(Achievements::Achievement) }
    let(:current_user) { instance_double(User) }

    before do
      allow(described_class).to receive(:authorized?).and_return(true)
    end

    it 'calls Achievement#avatar_url(only_path: false)' do
      allow(object).to receive(:avatar_url).with(only_path: false)
      resolve_field(:avatar_url, object, current_user: current_user)
      expect(object).to have_received(:avatar_url).with(only_path: false).once
    end
  end
end
