# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagsHelper do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:feature_flag) { create(:operations_feature_flag, project: project) }
  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:can?).and_return(true)
    allow(helper).to receive(:current_user).and_return(user)

    self.instance_variable_set(:@project, project)
    self.instance_variable_set(:@feature_flag, feature_flag)
  end

  describe '#unleash_api_url' do
    subject { helper.unleash_api_url(project) }

    it { is_expected.to end_with("/api/v4/feature_flags/unleash/#{project.id}") }
  end

  describe '#unleash_api_instance_id' do
    subject { helper.unleash_api_instance_id(project) }

    it { is_expected.not_to be_empty }
  end

  describe '#edit_feature_flag_data' do
    subject { helper.edit_feature_flag_data }

    it 'contains all the data needed to edit feature flags' do
      is_expected.to include(
        endpoint: "/#{project.full_path}/-/feature_flags/#{feature_flag.iid}",
        project_id: project.id,
        feature_flags_path: "/#{project.full_path}/-/feature_flags",
        environments_endpoint: "/#{project.full_path}/-/environments/search.json",
        strategy_type_docs_page_path: "/help/operations/feature_flags.md#feature-flag-strategies",
        environments_scope_docs_path: "/help/ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable"
      )
    end
  end
end
