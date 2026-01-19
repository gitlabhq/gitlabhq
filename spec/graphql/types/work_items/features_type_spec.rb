# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::FeaturesType, feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('WorkItemFeatures') }

  it 'exposes widget fields' do
    fields = WorkItems::WidgetDefinition.widget_classes.map(&:type)

    expect(described_class).to have_graphql_fields(*fields).at_least
  end
end
