module Issuable
  class BulkUpdateService < IssuableBaseService
    def execute(type)
      model_class = type.classify.constantize
      update_class = type.classify.pluralize.constantize::UpdateService

      ids = params.delete(:issuable_ids).split(",")
      items = model_class.where(id: ids)

      %i[state_event milestone_id assignee_id add_label_ids remove_label_ids subscription_event].each do |key|
        params.delete(key) unless params[key].present?
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
  end
end
