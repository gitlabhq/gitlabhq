# frozen_string_literal: true

module Labels
  class CreateService < Labels::BaseService
    def initialize(params = {})
      @params = params.to_h.dup.with_indifferent_access
    end

    # returns the created label
    def execute(target_params)
      params[:color] = convert_color_name_to_hex if params[:color].present?

      project_or_group = target_params[:project] || target_params[:group]

      if project_or_group.present?
        params.delete(:lock_on_merge) unless project_or_group.supports_lock_on_merge?

        project_or_group.labels.create(params)
      elsif target_params[:template]
        label = Label.new(params)
        label.organization_id = target_params[:organization_id]
        label.template = true
        label.save
        label
      else
        Gitlab::AppLogger.warn("target_params should contain :project or :group or :template, actual value: #{target_params}")
      end
    end
  end
end
