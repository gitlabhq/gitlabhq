module Issuable
  class BulkUpdateService < IssuableBaseService
    def execute(type)
      model_class = type.classify.constantize
      update_class = type.classify.pluralize.constantize::UpdateService

      ids = params.delete(:issuable_ids).split(",")
      items = model_class.where(id: ids)

      # https://gitlab.com/gitlab-org/gitlab-ce/issues/28836
      Rails.logger.info("BulkUpdateService received created for type: #{type} with IDs: #{ids.inspect} and params: #{params.inspect}")

      %i(state_event milestone_id assignee_id add_label_ids remove_label_ids subscription_event).each do |key|
        params.delete(key) unless params[key].present?
      end

      items.each do |issuable|
        next unless can?(current_user, :"update_#{type}", issuable)

        # https://gitlab.com/gitlab-org/gitlab-ce/issues/28836
        Rails.logger.info("BulkUpdateService created #{update_class} for #{issuable.to_reference(full: true)} with params: #{params.inspect}")

        update_class.new(issuable.project, current_user, params).execute(issuable)
      end

      {
        count:    items.count,
        success:  !items.count.zero?
      }
    end
  end
end
