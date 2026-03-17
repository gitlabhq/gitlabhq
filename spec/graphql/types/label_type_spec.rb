# frozen_string_literal: true
require 'spec_helper'

RSpec.describe GitlabSchema.types['Label'], feature_category: :team_planning do
  it 'has the correct fields' do
    expected_fields = [
      :id,
      :description,
      :description_html,
      :title,
      :color,
      :lock_on_merge,
      :text_color,
      :created_at,
      :updated_at,
      :archived
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_label) }
end
