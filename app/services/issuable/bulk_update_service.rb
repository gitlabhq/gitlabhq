# frozen_string_literal: true

module Issuable
  class BulkUpdateService < IssuableBaseService
    def execute(type)
      model_class = type.classify.constantize
      update_class = type.classify.pluralize.constantize::UpdateService

      ids = params.delete(:issuable_ids).split(",")
      items = model_class.where(id: ids)

      permitted_attrs(type).each do |key|
        params.delete(key) unless params[key].present?
      end

      if params[:assignee_ids] == [IssuableFinder::NONE.to_s]
        params[:assignee_ids] = []
      end

      items.each do |issuable|
        next unless can?(current_user, :"update_#{type}", issuable)

        update_class.new(issuable.project, current_user, params).execute(issuable)
      end

      {
        count:    items.count,
        success:  !items.count.zero?
      }
    end

    private

    def permitted_attrs(type)
      attrs = %i(state_event milestone_id assignee_id assignee_ids add_label_ids remove_label_ids subscription_event)

      if type == 'issue'
        attrs.push(:assignee_ids)
      else
        attrs.push(:assignee_id)
      end
    end
  end
end
