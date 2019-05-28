# frozen_string_literal: true

class ProjectSerializer < BaseSerializer
  def represent(project, opts = {})
    entity =
      case opts[:serializer]
      when :import
        ProjectImportEntity
      else
        ProjectEntity
      end

    super(project, opts, entity)
  end
end
