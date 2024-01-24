# frozen_string_literal: true

module Preloaders
  class ProjectRootAncestorPreloader
    def initialize(projects, namespace_sti_name = :namespace, root_ancestor_preloads = [])
      @projects = projects
      @namespace_sti_name = namespace_sti_name
      @root_ancestor_preloads = root_ancestor_preloads
    end

    def execute
      return unless @projects.is_a?(ActiveRecord::Relation)

      root_query = Namespace.joins("INNER JOIN (#{join_sql}) as root_query ON root_query.root_id = namespaces.id")
                        .select('namespaces.*, root_query.project_id as source_id')

      root_query = root_query.preload(*@root_ancestor_preloads) if @root_ancestor_preloads.any?

      root_ancestors_by_id = root_query.group_by(&:source_id)

      ActiveRecord::Associations::Preloader.new(records: @projects, associations: :namespace).call
      @projects.each do |project|
        root_ancestor = root_ancestors_by_id[project.id]&.first
        project.namespace.root_ancestor = root_ancestor if root_ancestor.present?
      end
    end

    private

    def join_sql
      @projects
        .joins(@namespace_sti_name)
        .select('projects.id as project_id, namespaces.traversal_ids[1] as root_id')
        .to_sql
    end
  end
end
