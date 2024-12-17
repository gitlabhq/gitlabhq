# frozen_string_literal: true

module WorkItems
  class UpdateService < ::Issues::UpdateService
    extend Gitlab::Utils::Override
    include WidgetableService

    def initialize(container:, current_user: nil, params: {}, perform_spam_check: false, widget_params: {})
      @extra_params = params.delete(:extra_params) || {}

      super(container: container, current_user: current_user, params: params, perform_spam_check: perform_spam_check)

      @widget_params = widget_params
    end

    def execute(work_item)
      updated_work_item = super

      if updated_work_item.valid?
        success(payload(work_item))
      else
        error(updated_work_item.errors.full_messages, :unprocessable_entity, pass_back: payload(updated_work_item))
      end
    rescue ::Issuable::Callbacks::Base::Error => e
      error(e.message, :unprocessable_entity)
    end

    private

    attr_reader :extra_params

    override :handle_date_changes
    def handle_date_changes(work_item)
      return if work_item.dates_source&.previous_changes.blank? &&
        work_item.previous_changes.slice('due_date', 'start_date').none?

      GraphqlTriggers.issuable_dates_updated(work_item)
    end

    override :associations_before_update
    def associations_before_update(work_item)
      super.merge(
        work_item_parent_id: work_item.work_item_parent&.id
      )
    end

    override :after_update
    def after_update(work_item, old_associations)
      super

      GraphqlTriggers.issuable_title_updated(work_item) if work_item.previous_changes.key?(:title)
      publish_event(work_item, old_associations)
    end

    def payload(work_item)
      { work_item: work_item }
    end

    def handle_label_changes(issuable, old_labels)
      return false unless super

      Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter.track_work_item_labels_changed_action(
        author: current_user
      )
    end

    def publish_event(work_item, old_associations)
      event = WorkItems::WorkItemUpdatedEvent.new(data: {
        id: work_item.id,
        namespace_id: work_item.namespace_id,
        previous_work_item_parent_id: old_associations[:work_item_parent_id],
        updated_attributes: work_item.previous_changes&.keys&.map(&:to_s),
        updated_widgets: @widget_params&.keys&.map(&:to_s)
      }.tap(&:compact_blank!))

      work_item.run_after_commit_or_now do
        Gitlab::EventStore.publish(event)
      end
    end

    def parent
      container
    end
  end
end

WorkItems::UpdateService.prepend_mod
