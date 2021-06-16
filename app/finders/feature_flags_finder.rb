# frozen_string_literal: true

class FeatureFlagsFinder
  attr_reader :project, :params, :current_user

  def initialize(project, current_user, params = {})
    @project = project
    @current_user = current_user
    @params = params
  end

  def execute(preload: true)
    unless Ability.allowed?(current_user, :read_feature_flag, project)
      return Operations::FeatureFlag.none
    end

    items = feature_flags
    items = by_scope(items)

    items = items.preload_relations if preload
    items.ordered
  end

  private

  def feature_flags
    project.operations_feature_flags.new_version_only
  end

  def by_scope(items)
    case params[:scope]
    when 'enabled'
      items.enabled
    when 'disabled'
      items.disabled
    else
      items
    end
  end
end
