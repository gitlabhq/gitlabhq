# frozen_string_literal: true

module FeatureFlags
  class HookService
    HOOK_NAME = :feature_flag_hooks

    def initialize(feature_flag, current_user)
      @feature_flag = feature_flag
      @current_user = current_user
    end

    def execute
      project.execute_hooks(hook_data, HOOK_NAME)
    end

    private

    attr_reader :feature_flag, :current_user

    def project
      @project ||= feature_flag.project
    end

    def hook_data
      Gitlab::DataBuilder::FeatureFlag.build(feature_flag, current_user)
    end
  end
end
