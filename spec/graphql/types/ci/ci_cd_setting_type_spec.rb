# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::CiCdSettingType, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('ProjectCiCdSetting') }

  it 'exposes the expected fields' do
    expected_fields = %w[
      inbound_job_token_scope_enabled job_token_scope_enabled
      keep_latest_artifact merge_pipelines_enabled project
      push_repository_for_job_token_allowed
    ]

    if Gitlab.ee?
      expected_fields += %w[
        merge_trains_skip_train_allowed merge_trains_enabled
      ]
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
