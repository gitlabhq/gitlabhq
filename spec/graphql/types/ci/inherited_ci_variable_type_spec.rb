# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['InheritedCiVariable'], feature_category: :secrets_management do
  specify do
    expect(described_class).to have_graphql_fields(
      :id,
      :key,
      :raw,
      :variable_type,
      :environment_scope,
      :masked,
      :protected,
      :group_name,
      :group_ci_cd_settings_path
    ).at_least
  end
end
