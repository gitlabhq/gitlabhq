# frozen_string_literal: true

module API
  module ProjectsRelationBuilder
    def prepare_relation(projects_relation, options = {})
      projects_relation = preload_relation(projects_relation, options)

      execute_batch_counting(projects_relation)

      postload_relation(projects_relation, options)

      preload_repository_cache(projects_relation)

      if options[:current_user]
        Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects_relation, options[:current_user]).execute
      end

      preload_member_roles(projects_relation, options[:current_user]) if options[:current_user]
      preload_groups(projects_relation) if options[:with] == Entities::Project

      projects_relation
    end

    # This is overridden by the specific Entity class to
    # preload assocations that it needs
    def preload_relation(projects_relation, _options = {})
      projects_relation
    end

    # This is overridden by the specific Entity class to
    # batch load certain counts
    def execute_batch_counting(projects_relation); end

    def preload_repository_cache(projects_relation)
      repositories = repositories_for_preload(projects_relation)

      Gitlab::RepositoryCache::Preloader.new(repositories).preload( # rubocop:disable CodeReuse/ActiveRecord
        %i[exists? root_ref has_visible_content? avatar readme_path]
      )
    end

    def repositories_for_preload(projects_relation)
      projects_relation.map(&:repository)
    end

    # For all projects except those in a user namespace, the `namespace`
    # and `group` are identical. Preload the group when it's not a user namespace.
    def preload_groups(projects_relation)
      group_projects = projects_for_group_preload(projects_relation)
      groups = group_projects.map(&:namespace)

      ::Namespaces::Preloaders::GroupRootAncestorPreloader.new(groups).execute

      group_projects.each do |project|
        project.group = project.namespace
      end
    end

    def projects_for_group_preload(projects_relation)
      projects_relation.select { |project| project.namespace.type == Group.sti_name }
    end

    def preload_member_roles(projects_relation, user)
      # overridden in EE
    end
  end
end

API::ProjectsRelationBuilder.prepend_mod
