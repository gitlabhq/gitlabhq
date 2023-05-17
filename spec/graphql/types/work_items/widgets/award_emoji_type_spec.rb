# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::AwardEmojiType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[award_emoji downvotes upvotes type]

    expect(described_class.graphql_name).to eq('WorkItemWidgetAwardEmoji')
    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
