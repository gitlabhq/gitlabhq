# frozen_string_literal: true

module Labels
  class UpdateService < Labels::BaseService
    def initialize(params = {})
      @params = params.to_h.dup.with_indifferent_access
    end

    # returns the updated label
    def execute(label)
      params[:name] = params.delete(:new_name) if params.key?(:new_name)
      params[:color] = convert_color_name_to_hex if params[:color].present?

      label.update(params)
      label
    end
  end
end
