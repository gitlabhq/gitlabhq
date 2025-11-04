# frozen_string_literal: true

module LoadedInGroupList
  extend ActiveSupport::Concern

  class_methods do
    def with_counts(archived: nil, active: nil)
      projects_cte = projects_cte(archived, active)
      subgroups_cte = subgroups_cte(archived, active)

      selects_including_counts = [
        'namespaces.*',
        "(#{project_count_sql(projects_cte).to_sql}) AS preloaded_project_count",
        "(#{member_count_sql.to_sql}) AS preloaded_member_count",
        "(#{subgroup_count_sql(subgroups_cte).to_sql}) AS preloaded_subgroup_count"
      ]

      select(selects_including_counts)
        .with(projects_cte.to_arel)
        .with(subgroups_cte.to_arel)
    end

    def with_selects_for_list(archived: nil, active: nil)
      with_route
        .with_namespace_details
        .with_counts(archived:, active:)
        .preload(:deletion_schedule, :namespace_settings, :namespace_settings_with_ancestors_inherited_settings)
    end

    private

    def by_archived(relation, archived)
      return relation if archived.nil?

      archived ? relation.self_or_ancestors_archived : relation.self_and_ancestors_non_archived
    end

    def by_active(relation, active)
      return relation if active.nil?

      active ? relation.self_and_ancestors_active : relation.self_or_ancestors_inactive
    end

    def projects_cte(archived = nil, active = nil)
      projects = Project.unscoped.select(:namespace_id)
      projects = by_archived(projects, archived)
      projects = by_active(projects, active)

      Gitlab::SQL::CTE.new(:projects_cte, projects, materialized: false)
    end

    def project_count_sql(cte)
      namespaces = Namespace.arel_table

      Arel::SelectManager.new
        .from(cte.table)
        .project(Arel.star.count.as('preloaded_project_count'))
        .where(cte.table[:namespace_id].eq(namespaces[:id]))
    end

    def subgroups_cte(archived = nil, active = nil)
      subgroups = Group.unscoped.select(:parent_id)
      subgroups = by_archived(subgroups, archived)
      subgroups = by_active(subgroups, active)

      Gitlab::SQL::CTE.new(:subgroups_cte, subgroups, materialized: false)
    end

    def subgroup_count_sql(cte)
      namespaces = Namespace.arel_table

      Arel::SelectManager.new
        .from(cte.table)
        .project(Arel.star.count.as('preloaded_subgroup_count'))
        .where(cte.table[:parent_id].eq(namespaces[:id]))
    end

    def member_count_sql
      members = Member.arel_table
      namespaces = Namespace.arel_table

      members.project(Arel.star.count.as('preloaded_member_count'))
        .where(members[:source_type].eq(Namespace.name))
        .where(members[:source_id].eq(namespaces[:id]))
        .where(members[:requested_at].eq(nil))
        .where(members[:access_level].gt(Gitlab::Access::MINIMAL_ACCESS))
    end
  end

  def children_count
    @children_count ||= project_count + subgroup_count
  end

  def project_count
    @project_count ||= try(:preloaded_project_count) || projects.non_archived.count
  end

  def subgroup_count
    @subgroup_count ||= try(:preloaded_subgroup_count) || children.count
  end

  def member_count
    @member_count ||= try(:preloaded_member_count) || members.count
  end

  def guest_count
    @guest_count ||= members.guests.count
  end

  def has_subgroups?
    subgroup_count > 0
  end
end

LoadedInGroupList::ClassMethods.prepend_mod_with('LoadedInGroupList::ClassMethods')
