# frozen_string_literal: true

module Ci
  class ChangeVariablesService < BaseContainerService
    def execute
      container.update(params)
    end
  end
end

::Ci::ChangeVariablesService.prepend_if_ee('EE::Ci::ChangeVariablesService')
