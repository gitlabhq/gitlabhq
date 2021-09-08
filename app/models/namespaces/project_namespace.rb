# frozen_string_literal: true

module Namespaces
  class ProjectNamespace < Namespace
    has_one :project, foreign_key: :project_namespace_id, inverse_of: :project_namespace

    def self.sti_name
      'Project'
    end
  end
end
