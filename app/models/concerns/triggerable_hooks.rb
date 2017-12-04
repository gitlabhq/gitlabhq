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

    private

    def triggerable_hooks(hooks)
      triggers = AVAILABLE_TRIGGERS.slice(*hooks)
      const_set('TRIGGERS', triggers)

      self::TRIGGERS.each do |trigger, event|
        scope trigger, -> { where(event => true) }
      end
    end
  end
end
