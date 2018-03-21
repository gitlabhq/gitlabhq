module TriggerableHooks
  AVAILABLE_TRIGGERS = {
    repository_update_hooks:  :repository_update_events,
    push_hooks:               :push_events,
    tag_push_hooks:           :tag_push_events,
    issue_hooks:              :issues_events,
    confidential_issue_hooks: :confidential_issues_events,
    note_hooks:               :note_events,
    merge_request_hooks:      :merge_requests_events,
    job_hooks:                :job_events,
    pipeline_hooks:           :pipeline_events,
    wiki_page_hooks:          :wiki_page_events
  }.freeze

  extend ActiveSupport::Concern

  class_methods do
    attr_reader :triggerable_hooks

    attr_reader :triggers

    def hooks_for(trigger)
      callable_scopes = triggers.keys + [:all]
      return none unless callable_scopes.include?(trigger)

      public_send(trigger) # rubocop:disable GitlabSecurity/PublicSend
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
