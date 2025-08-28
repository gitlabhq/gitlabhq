# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiGroupEnvironmentScope'], feature_category: :pipeline_composition do
  specify do
    expect(described_class).to have_graphql_fields(
      :name
    ).at_least
  end
end
