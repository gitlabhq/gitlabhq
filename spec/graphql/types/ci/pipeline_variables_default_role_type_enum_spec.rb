# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineVariablesDefaultRoleType'], feature_category: :ci_variables do
  it 'matches the keys of ProjectCiCdSetting.pipeline_variables_minimum_override_role' do
    expect(described_class.values.keys)
      .to match_array(%w[NO_ONE_ALLOWED DEVELOPER MAINTAINER OWNER])
  end
end
