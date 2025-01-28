# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['InheritedCiVariable'], feature_category: :ci_variables do
  specify do
    expect(described_class).to have_graphql_fields(
      :id,
      :key,
      :description,
      :environment_scope,
      :group_name,
      :group_ci_cd_settings_path,
      :masked,
      :protected,
      :raw,
      :variable_type
    ).at_least
  end
end
