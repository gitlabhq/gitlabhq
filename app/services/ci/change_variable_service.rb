# frozen_string_literal: true

module Ci
  class ChangeVariableService < BaseContainerService
    def execute
      case params[:action]
      when :create
        container.variables.create(params[:variable_params])
      when :update
        variable.tap do |target_variable|
          target_variable.update(params[:variable_params].except(:key))
        end
      when :destroy
        variable.tap do |target_variable|
          target_variable.destroy
        end
      end
    end

    private

    def variable
      params[:variable] || find_variable
    end

    def find_variable
      identifier = params[:variable_params].slice(:id).presence || params[:variable_params].slice(:key)
      container.variables.find_by!(identifier) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end

::Ci::ChangeVariableService.prepend_mod_with('Ci::ChangeVariableService')
