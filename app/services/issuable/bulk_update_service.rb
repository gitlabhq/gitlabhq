# frozen_string_literal: true

module Issuable
  class BulkUpdateService
    include Gitlab::Allowable

    attr_accessor :parent, :current_user, :params

    def initialize(parent, user = nil, params = {})
      @parent = parent
      @current_user = user
      @params = params.dup
    end

    def execute(type)
      model_ids = ids_from_params(params.delete(:issuable_ids))
      set_update_params(type)
      updated_issuables = update_issuables(type, model_ids)

      if updated_issuables.present? && requires_count_cache_reset?(type)
        schedule_group_issues_count_reset(updated_issuables)
      end

      response_success(payload: { count: updated_issuables.size })
    rescue ArgumentError => e
      response_error(e.message, 422)
    end

    private

    def ids_from_params(issuable_ids)
      return issuable_ids if issuable_ids.is_a?(Array)

      issuable_ids.split(',')
    end

    def set_update_params(type)
      params.slice!(*permitted_attrs(type))

      if params[:assignee_ids] == [IssuableFinder::Params::NONE.to_s]
        params[:assignee_ids] = []
      end
    end

    def permitted_attrs(type)
      attrs = %i[state_event milestone_id add_label_ids remove_label_ids subscription_event]

      if type == 'issue'
        attrs.push(:assignee_ids, :confidential)
      elsif type == 'merge_request'
        attrs.push(:assignee_ids)
      else
        attrs.push(:assignee_id)
      end
    end

    def update_issuables(type, ids)
      model_class = type.classify.constantize
      update_class = type.classify.pluralize.constantize::UpdateService
      items = find_issuables(parent, model_class, ids)
      authorized_issuables = []

      items.each do |issuable|
        next unless can?(current_user, :"update_#{type}", issuable)

        authorized_issuables << issuable
        update_class.new(
          **update_class.constructor_container_arg(issuable.issuing_parent),
          current_user: current_user,
          params: dup_params
        ).execute(issuable)
      end

      authorized_issuables
    end

    def find_issuables(parent, model_class, ids)
      issuables = model_class.id_in(ids)

      case parent
      when Project
        issuables = issuables.of_projects(parent)
      when Group
        issuables = issuables.of_projects(parent.all_projects)
      else
        raise ArgumentError, _('A parent must be provided when bulk updating issuables')
      end

      issuables.includes_for_bulk_update
    end

    # Duplicates params and its top-level values
    # We cannot use deep_dup because ActiveRecord objects will result
    # to new records with no id assigned
    def dup_params
      dup = HashWithIndifferentAccess.new

      params.each do |key, value|
        dup[key] = value.is_a?(ActiveRecord::Base) ? value : value.dup
      end

      dup
    end

    def response_success(message: nil, payload: nil)
      ServiceResponse.success(message: message, payload: payload)
    end

    def response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end

    def requires_count_cache_reset?(type)
      type.to_sym == :issue && params.include?(:state_event)
    end

    def schedule_group_issues_count_reset(updated_issuables)
      group_ids = updated_issuables.map(&:project).map(&:namespace_id)
      return if group_ids.empty?

      Issuables::ClearGroupsIssueCounterWorker.perform_async(group_ids)
    end
  end
end

Issuable::BulkUpdateService.prepend_mod_with('Issuable::BulkUpdateService')
