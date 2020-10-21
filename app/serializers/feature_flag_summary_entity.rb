# frozen_string_literal: true

class FeatureFlagSummaryEntity < Grape::Entity
  include RequestAwareEntity

  expose :count do
    expose :all do |project|
      project.operations_feature_flags.count
    end

    expose :enabled do |project|
      project.operations_feature_flags.enabled.count
    end

    expose :disabled do |project|
      project.operations_feature_flags.disabled.count
    end
  end
end
