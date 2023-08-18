# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::VariablesHelper, feature_category: :secrets_management do
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

  describe '#ci_variable_protected?' do
    let(:variable) { build_stubbed(:ci_variable, key: 'test_key', value: 'test_value', protected: true) }

    context 'when variable is provided and only_key_value is false' do
      it 'expect ci_variable_protected? to return true' do
        expect(helper.ci_variable_protected?(variable, false)).to eq(true)
      end
    end

    context 'when variable is not provided / provided and only_key_value is true' do
      it 'is equal to the value of ci_variable_protected_by_default?' do
        expect(helper.ci_variable_protected?(nil, true)).to eq(
          helper.ci_variable_protected_by_default?
        )

        expect(helper.ci_variable_protected?(variable, true)).to eq(
          helper.ci_variable_protected_by_default?
        )
      end
    end
  end

  describe '#ci_variable_masked?' do
    let(:variable) { build_stubbed(:ci_variable, key: 'test_key', value: 'test_value', masked: true) }

    context 'when variable is provided and only_key_value is false' do
      it 'expect ci_variable_masked? to return true' do
        expect(helper.ci_variable_masked?(variable, false)).to eq(true)
      end
    end

    context 'when variable is not provided / provided and only_key_value is true' do
      it 'expect ci_variable_masked? to return false' do
        expect(helper.ci_variable_masked?(nil, true)).to eq(false)
        expect(helper.ci_variable_masked?(variable, true)).to eq(false)
      end
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
