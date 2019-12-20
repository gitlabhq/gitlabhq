# frozen_string_literal: true

module Issuable
  class BulkUpdateService
    include Gitlab::Allowable

    attr_accessor :parent, :current_user, :params

    def initialize(parent, user = nil, params = {})
      @parent, @current_user, @params = parent, user, params.dup
    end

    def execute(type)
      model_class = type.classify.constantize
      update_class = type.classify.pluralize.constantize::UpdateService

      ids = params.delete(:issuable_ids).split(",")
      items = find_issuables(parent, model_class, ids)

      permitted_attrs(type).each do |key|
        params.delete(key) unless params[key].present?
      end

      if params[:assignee_ids] == [IssuableFinder::NONE.to_s]
        params[:assignee_ids] = []
      end

      items.each do |issuable|
        next unless can?(current_user, :"update_#{type}", issuable)

        update_class.new(issuable.issuing_parent, current_user, params).execute(issuable)
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

    def find_issuables(parent, model_class, ids)
      if parent.is_a?(Project)
        model_class.id_in(ids).of_projects(parent)
      elsif parent.is_a?(Group)
        model_class.id_in(ids).of_projects(parent.all_projects)
      end
    end
  end
end

Issuable::BulkUpdateService.prepend_if_ee('EE::Issuable::BulkUpdateService')
