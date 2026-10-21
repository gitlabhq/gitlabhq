# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Triggers
      DEPLOYMENT_REQUESTED = 'deployment_requested'
      ENVIRONMENT_ADVANCED = 'environment_advanced'
      DEPLOYMENT_PROMOTED = 'deployment_promoted'
      PROJECT_SETTINGS_CHANGE_REQUESTED = 'project.before_settings_update'
      PROJECT_SETTINGS_DRIFT_CHECKED = 'project.scheduled_settings_drift_check'
      PROJECT_CREATED = 'project.after_create'
      PROJECT_TRANSFERRED = 'project.after_transfer'

      # TYPES is the persisted vocabulary, in Govern enum order, including the
      # internal ids the engine records on evaluations. ALL is the authoring
      # catalogue and stays a subset of TYPES; the settings ids enter it once
      # the editor offers them.
      TYPES = [
        DEPLOYMENT_REQUESTED, ENVIRONMENT_ADVANCED, DEPLOYMENT_PROMOTED,
        PROJECT_SETTINGS_CHANGE_REQUESTED, PROJECT_SETTINGS_DRIFT_CHECKED,
        PROJECT_CREATED, PROJECT_TRANSFERRED
      ].freeze

      ALL = [
        { id: DEPLOYMENT_REQUESTED, name: 'Deployment requested' }.freeze,
        { id: ENVIRONMENT_ADVANCED, name: 'Environment advanced' }.freeze,
        { id: DEPLOYMENT_PROMOTED, name: 'Deployment promoted' }.freeze
      ].freeze
    end
  end
end
