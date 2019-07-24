# frozen_string_literal: true

module Projects
  class BaseMoveRelationsService < BaseService
    attr_reader :source_project
    def execute(source_project, remove_remaining_elements: true)
      return if source_project.blank?

      @source_project = source_project

      true
    end

    private

    def prepare_relation(relation, id_param = :id)
      # TODO: Refactor and remove this method (https://gitlab.com/gitlab-org/gitlab-ce/issues/65054)
      relation
    end
  end
end
