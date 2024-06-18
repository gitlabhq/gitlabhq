# frozen_string_literal: true

class FeatureFlagEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :active
  expose :created_at
  expose :updated_at
  expose :name
  expose :description
  expose :version

  expose :edit_path, if: ->(feature_flag, _) { can_update?(feature_flag) } do |feature_flag|
    edit_project_feature_flag_path(feature_flag.project, feature_flag)
  end

  expose :update_path, if: ->(feature_flag, _) { can_update?(feature_flag) } do |feature_flag|
    project_feature_flag_path(feature_flag.project, feature_flag)
  end

  expose :destroy_path, if: ->(feature_flag, _) { can_destroy?(feature_flag) } do |feature_flag|
    project_feature_flag_path(feature_flag.project, feature_flag)
  end

  expose :scopes do |_ff|
    []
  end

  expose :strategies, with: FeatureFlags::StrategyEntity do |feature_flag|
    feature_flag.strategies.sort_by(&:id)
  end

  private

  def can_update?(feature_flag)
    can?(current_user, :update_feature_flag, feature_flag)
  end

  def can_destroy?(feature_flag)
    can?(current_user, :destroy_feature_flag, feature_flag)
  end

  def current_user
    request.current_user
  end
end
