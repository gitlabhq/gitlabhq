# frozen_string_literal: true

module Ci
  class ChangeVariableService < BaseContainerService
    def execute
      case params[:action]
      when :create
        container.variables.create(create_variable_params)
      when :update
        variable.tap do |target_variable|
          target_variable.update(update_variable_params.except(:key))
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

    def create_variable_params
      params[:variable_params].tap do |variables|
        if variables[:masked_and_hidden]
          variables[:hidden] = true
          variables[:masked] = true
        end

        variables.delete(:masked_and_hidden)
      end
    end

    def update_variable_params
      params[:variable_params]
    end

    def find_variable
      identifier = params[:variable_params].slice(:id).presence || params[:variable_params].slice(:key)
      container.variables.find_by!(identifier) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end

::Ci::ChangeVariableService.prepend_mod_with('Ci::ChangeVariableService')
