# frozen_string_literal: true

module Projects
  class BaseMoveRelationsService < BaseService
    attr_reader :source_project

    def execute(source_project, remove_remaining_elements: true)
      return if source_project.blank?

      @source_project = source_project

      true
    end
  end
end
