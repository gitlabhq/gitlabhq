# frozen_string_literal: true

module LoadedInGroupList
  extend ActiveSupport::Concern

  class_methods do
    def with_counts(archived:)
      selects_including_counts = [
        'namespaces.*',
        "(#{project_count_sql(archived).to_sql}) AS preloaded_project_count",
        "(#{member_count_sql.to_sql}) AS preloaded_member_count",
        "(#{subgroup_count_sql.to_sql}) AS preloaded_subgroup_count"
      ]

      select(selects_including_counts)
    end

    def with_selects_for_list(archived: nil)
      with_route.with_namespace_details.with_counts(archived: archived).preload(:deletion_schedule)
    end

    private

    def project_count_sql(archived = nil)
      projects = Project.arel_table
      namespaces = Namespace.arel_table

      base_count = projects.project(Arel.star.count.as('preloaded_project_count'))
                     .where(projects[:namespace_id].eq(namespaces[:id]))

      if archived == 'only'
        base_count.where(projects[:archived].eq(true))
      elsif Gitlab::Utils.to_boolean(archived)
        base_count
      else
        base_count.where(projects[:archived].not_eq(true))
      end
    end

    def subgroup_count_sql
      namespaces = Namespace.arel_table
      children = namespaces.alias('children')

      # TODO 6473: remove the filtering of the Namespaces::ProjectNamespace see https://gitlab.com/groups/gitlab-org/-/epics/6473
      namespaces.project(Arel.star.count.as('preloaded_subgroup_count'))
        .from(children)
        .where(children[:parent_id].eq(namespaces[:id]))
        .where(children[:type].is_distinct_from(Namespaces::ProjectNamespace.sti_name))
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
