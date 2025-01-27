# frozen_string_literal: true

module Namespaces
  class ProjectNamespace < Namespace
    self.allow_legacy_sti_class = true

    # These aliases are added to make it easier to sync parent/parent_id attribute with
    # project.namespace/project.namespace_id attribute.
    #
    # TODO: we can remove these attribute aliases when we no longer need to sync these with project model,
    # see ProjectNamespace#sync_attributes_from_project
    alias_attribute :namespace, :parent
    alias_attribute :namespace_id, :parent_id
    has_one :project, inverse_of: :project_namespace

    delegate :execute_hooks, :execute_integrations, :group, to: :project, allow_nil: true
    delegate :external_references_supported?, :default_issues_tracker?, :pending_delete?, to: :project

    delegate :crm_group, :hashed_storage?, :disk_path, to: :project

    def self.sti_name
      'Project'
    end

    def self.polymorphic_name
      'Namespaces::ProjectNamespace'
    end

    def self.create_from_project!(project)
      return unless project.new_record?
      return unless project.namespace

      proj_namespace = project.project_namespace || project.build_project_namespace
      project.project_namespace.sync_attributes_from_project(project)
      proj_namespace.save!
      proj_namespace
    end

    def sync_attributes_from_project(project)
      attribute_list = %w[name path namespace_id namespace visibility_level shared_runners_enabled organization_id]

      attributes_to_sync = project
                             .changes
                             .slice(*attribute_list)
                             .transform_values { |val| val[1] }

      # if visibility_level is not set explicitly for project, it defaults to 0,
      # but for namespace visibility_level defaults to 20,
      # so it gets out of sync right away if we do not set it explicitly when creating the project namespace
      attributes_to_sync['visibility_level'] ||= project.visibility_level if project.new_record?

      # when a project is associated with a group while the group is created we need to ensure we associate the new
      # group with the project namespace as well.
      # E.g.
      # project = create(:project) <- project is saved
      # create(:group, projects: [project]) <- associate project with a group that is not yet created.
      if attributes_to_sync.has_key?('namespace_id') &&
          attributes_to_sync['namespace_id'].blank? &&
          project.namespace.present?
        attributes_to_sync['parent'] = project.namespace
      end

      assign_attributes(attributes_to_sync)
    end

    # It's always 1 project but it has to be an AR relation
    def all_projects
      Project.where(id: project.id)
    end
  end
end

Namespaces::ProjectNamespace.prepend_mod
