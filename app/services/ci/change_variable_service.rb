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
      container.variables.find_by!(params[:variable_params].slice(:key)) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end

::Ci::ChangeVariableService.prepend_if_ee('EE::Ci::ChangeVariableService')
