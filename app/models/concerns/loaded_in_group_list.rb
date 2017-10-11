module LoadedInGroupList
  extend ActiveSupport::Concern

  PROJECT_COUNT_SQL = <<~PROJECTCOUNT.freeze
                     SELECT COUNT(*) AS preloaded_project_count
                     FROM projects
                     WHERE projects.namespace_id = namespaces.id
                     PROJECTCOUNT
  SUBGROUP_COUNT_SQL = <<~SUBGROUPCOUNT.freeze
                     (SELECT COUNT(*) AS preloaded_subgroup_count
                     FROM namespaces children
                     WHERE children.parent_id = namespaces.id)
                     SUBGROUPCOUNT
  MEMBER_COUNT_SQL = <<~MEMBERCOUNT.freeze
                     (SELECT COUNT(*) AS preloaded_member_count
                     FROM members
                     WHERE members.source_type = 'Namespace'
                     AND members.source_id = namespaces.id
                     AND members.requested_at IS NULL)
                     MEMBERCOUNT

  COUNT_SELECTS = ['namespaces.*',
                   SUBGROUP_COUNT_SQL,
                   MEMBER_COUNT_SQL].freeze

  module ClassMethods
    def with_counts(archived:)
      selects = COUNT_SELECTS.dup << project_count(archived)
      select(selects)
    end

    def with_selects_for_list(archived: nil)
      with_route.with_counts(archived: archived)
    end

    def project_count(archived)
      project_count = if archived == 'only'
                        PROJECT_COUNT_SQL + 'AND projects.archived IS true'
                      elsif Gitlab::Utils.to_boolean(archived)
                        PROJECT_COUNT_SQL
                      else
                        PROJECT_COUNT_SQL + 'AND projects.archived IS NOT true'
                      end
      "(#{project_count})"
    end
  end

  def children_count
    @children_count ||= project_count + subgroup_count
  end

  def project_count
    @project_count ||= if respond_to?(:preloaded_project_count)
                         preloaded_project_count
                       else
                         projects.non_archived.count
                       end
  end

  def subgroup_count
    @subgroup_count ||= if respond_to?(:preloaded_subgroup_count)
                          preloaded_subgroup_count
                        else
                          children.count
                        end
  end

  def member_count
    @member_count ||= if respond_to?(:preloaded_member_count)
                        preloaded_member_count
                      else
                        users.count
                      end
  end
end
