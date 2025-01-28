# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::VariablesHelper, feature_category: :ci_variables do
  describe '#create_deploy_token_path' do
    let_it_be(:group) { build_stubbed(:group) }
    let_it_be(:project) { build_stubbed(:project) }

    it 'returns the project deploy token path' do
      expect(helper.create_deploy_token_path(project)).to eq(
        create_deploy_token_project_settings_repository_path(project, {})
      )
    end

    it 'returns the group deploy token path' do
      expect(helper.create_deploy_token_path(group)).to eq(
        create_deploy_token_group_settings_repository_path(group, {})
      )
    end
  end

  describe '#ci_variable_maskable_raw_regex' do
    it 'converts to a javascript regex' do
      expect(helper.ci_variable_maskable_raw_regex).to eq("^\\S{8,}$")
    end
  end

  describe '#ci_variable_maskable_regex' do
    it 'converts to a javascript regex' do
      expect(helper.ci_variable_maskable_regex).to eq("^[a-zA-Z0-9_+=/@:.~-]{8,}$")
    end
  end
end
