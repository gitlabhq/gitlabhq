# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Triggers
      # GOVERN-016's kinds. A `gate` trigger is asked before the change and may be
      # answered by stopping it; an `event` trigger is told after the fact and cannot
      # be. Nothing here enforces that pairing yet: kind is published so callers can
      # reason about it, and the save path learns to refuse a blocking action on an
      # event in https://gitlab.com/gitlab-org/gitlab/-/issues/631712. Its third kind,
      # `schedule`, has no authorable trigger yet.
      # https://gitlab.com/gitlab-org/architecture/govern/design-doc/-/merge_requests/28
      KIND_GATE = 'gate'
      KIND_EVENT = 'event'

      DEPLOYMENT_REQUESTED = 'deployment_requested'
      ENVIRONMENT_ADVANCED = 'environment_advanced'
      DEPLOYMENT_PROMOTED = 'deployment_promoted'
      PROJECT_SETTINGS_CHANGE_REQUESTED = 'project.before_settings_update'
      PROJECT_SETTINGS_DRIFT_CHECKED = 'project.scheduled_settings_drift_check'
      PROJECT_CREATED = 'project.after_create'
      PROJECT_TRANSFERRED = 'project.after_transfer'

      # TYPES is the persisted vocabulary, in Govern enum order, including the
      # internal ids the engine records on evaluations. ALL is the authoring
      # catalogue and stays a subset of TYPES: the drift check is recorded by the
      # engine on a schedule and is never authored, so it stays out of ALL.
      TYPES = [
        DEPLOYMENT_REQUESTED, ENVIRONMENT_ADVANCED, DEPLOYMENT_PROMOTED,
        PROJECT_SETTINGS_CHANGE_REQUESTED, PROJECT_SETTINGS_DRIFT_CHECKED,
        PROJECT_CREATED, PROJECT_TRANSFERRED
      ].freeze

      ALL = [
        { id: DEPLOYMENT_REQUESTED, name: 'Deployment requested', kind: KIND_GATE }.freeze,
        { id: ENVIRONMENT_ADVANCED, name: 'Environment advanced', kind: KIND_GATE }.freeze,
        { id: DEPLOYMENT_PROMOTED, name: 'Deployment promoted', kind: KIND_GATE }.freeze,
        { id: PROJECT_SETTINGS_CHANGE_REQUESTED, name: 'Project settings change requested',
          kind: KIND_GATE }.freeze,
        # Creation inherits some settings only after the project row exists, so there
        # is nothing left to gate by the time these fire.
        { id: PROJECT_CREATED, name: 'Project created', kind: KIND_EVENT }.freeze,
        { id: PROJECT_TRANSFERRED, name: 'Project transferred', kind: KIND_EVENT }.freeze
      ].freeze
    end
  end
end
