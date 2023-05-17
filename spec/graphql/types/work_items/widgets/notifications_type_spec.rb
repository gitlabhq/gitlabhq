# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::NotificationsType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[subscribed type]

    expect(described_class.graphql_name).to eq('WorkItemWidgetNotifications')
    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
