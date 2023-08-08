# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineTrigger'], feature_category: :continuous_integration do
  specify do
    expect(described_class).to have_graphql_fields(%i[
      can_access_project
      description
      has_token_exposed
      last_used
      id
      owner
      token
    ]).at_least
  end
end
