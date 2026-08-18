# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['QuickActionCommand'], feature_category: :code_review_workflow do
  specify do
    expect(described_class).to have_graphql_fields(
      :name, :aliases, :description, :params, :warning, :icon
    )
  end
end
