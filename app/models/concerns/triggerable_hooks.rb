# frozen_string_literal: true

module TriggerableHooks
  AVAILABLE_TRIGGERS = {
    repository_update_hooks:  :repository_update_events,
    push_hooks:               :push_events,
    tag_push_hooks:           :tag_push_events,
    issue_hooks:              :issues_events,
    confidential_note_hooks:  :confidential_note_events,
    confidential_issue_hooks: :confidential_issues_events,
    note_hooks:               :note_events,
    merge_request_hooks:      :merge_requests_events,
    job_hooks:                :job_events,
    pipeline_hooks:           :pipeline_events,
    wiki_page_hooks:          :wiki_page_events,
    deployment_hooks:         :deployment_events,
    feature_flag_hooks:       :feature_flag_events,
    release_hooks:            :releases_events,
    member_hooks:             :member_events,
    subgroup_hooks:           :subgroup_events
  }.freeze

  extend ActiveSupport::Concern

  class_methods do
    attr_reader :triggers

    def hooks_for(trigger)
      callable_scopes = triggers.keys + [:all]
      return none unless callable_scopes.include?(trigger)

      executable.public_send(trigger) # rubocop:disable GitlabSecurity/PublicSend
    end

    def select_active(hooks_scope, data)
      executable.select do |hook|
        ActiveHookFilter.new(hook).matches?(hooks_scope, data)
      end
    end

    private

    def triggerable_hooks(hooks)
      triggers = AVAILABLE_TRIGGERS.slice(*hooks)
      @triggers = triggers

      triggers.each do |trigger, event|
        scope trigger, -> { where(event => true) }
      end
    end
  end
end
