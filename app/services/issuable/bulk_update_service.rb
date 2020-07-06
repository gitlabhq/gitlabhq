# frozen_string_literal: true

module Issuable
  class BulkUpdateService
    include Gitlab::Allowable

    attr_accessor :parent, :current_user, :params

    def initialize(parent, user = nil, params = {})
      @parent, @current_user, @params = parent, user, params.dup
    end

    def execute(type)
      ids = params.delete(:issuable_ids).split(",")
      set_update_params(type)
      items = update_issuables(type, ids)

      response_success(payload: { count: items.count })
    rescue ArgumentError => e
      response_error(e.message, 422)
    end

    private

    def set_update_params(type)
      params.slice!(*permitted_attrs(type))
      params.delete_if { |k, v| v.blank? }

      if params[:assignee_ids] == [IssuableFinder::Params::NONE.to_s]
        params[:assignee_ids] = []
      end
    end

    def permitted_attrs(type)
      attrs = %i(state_event milestone_id add_label_ids remove_label_ids subscription_event)

      if type == 'issue' || type == 'merge_request'
        attrs.push(:assignee_ids)
      else
        attrs.push(:assignee_id)
      end
    end

    def update_issuables(type, ids)
      model_class = type.classify.constantize
      update_class = type.classify.pluralize.constantize::UpdateService
      items = find_issuables(parent, model_class, ids)

      items.each do |issuable|
        next unless can?(current_user, :"update_#{type}", issuable)

        update_class.new(issuable.issuing_parent, current_user, params).execute(issuable)
      end

      items
    end

    def find_issuables(parent, model_class, ids)
      if parent.is_a?(Project)
        model_class.id_in(ids).of_projects(parent)
      elsif parent.is_a?(Group)
        model_class.id_in(ids).of_projects(parent.all_projects)
      end
    end

    def response_success(message: nil, payload: nil)
      ServiceResponse.success(message: message, payload: payload)
    end

    def response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end
  end
end

Issuable::BulkUpdateService.prepend_if_ee('EE::Issuable::BulkUpdateService')
