# frozen_string_literal: true

module WorkItems
  class UpdateService < ::Issues::UpdateService
    include WidgetableService

    def initialize(container:, current_user: nil, params: {}, spam_params: nil, widget_params: {})
      params[:widget_params] = true if widget_params.present?

      super(container: container, current_user: current_user, params: params, spam_params: spam_params)

      @widget_params = widget_params
    end

    def execute(work_item)
      updated_work_item = super

      if updated_work_item.valid?
        success(payload(work_item))
      else
        error(updated_work_item.errors.full_messages, :unprocessable_entity, pass_back: payload(updated_work_item))
      end
    rescue ::WorkItems::Widgets::BaseService::WidgetError => e
      error(e.message, :unprocessable_entity)
    end

    private

    def prepare_update_params(work_item)
      execute_widgets(
        work_item: work_item,
        callback: :prepare_update_params,
        widget_params: @widget_params,
        service_params: params
      )

      super
    end

    def before_update(work_item, skip_spam_check: false)
      execute_widgets(work_item: work_item, callback: :before_update_callback, widget_params: @widget_params)

      super
    end

    def transaction_update(work_item, opts = {})
      execute_widgets(work_item: work_item, callback: :before_update_in_transaction, widget_params: @widget_params)

      super
    end

    def after_update(work_item, old_associations)
      super

      GraphqlTriggers.issuable_title_updated(work_item) if work_item.previous_changes.key?(:title)
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
  end
end
