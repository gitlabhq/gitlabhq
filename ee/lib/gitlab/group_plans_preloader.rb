# frozen_string_literal: true

module Gitlab
  # Preloading of Plans for one or more groups.
  #
  # This class can be used to efficiently preload the plans of a given list of
  # groups, including any plans the groups may have access to based on their
  # parent groups.
  class GroupPlansPreloader
    # Preloads all the plans for the given Groups.
    #
    # groups - An ActiveRecord::Relation returning a set of Group instances.
    #
    # Returns an Array containing all the Groups, including their preloaded
    # plans.
    def preload(groups)
      groups_and_ancestors = groups_and_ancestors_for(groups)

      # A Hash mapping group IDs to their corresponding Group instances.
      groups_map = groups_and_ancestors.each_with_object({}) do |group, hash|
        hash[group.id] = group
      end

      all_plan_ids = Set.new

      # A Hash that for every group ID maps _all_ the plan IDs this group has
      # access to.
      plans_map = groups_and_ancestors
        .each_with_object(Hash.new { |h, k| h[k] = [] }) do |group, hash|
          current = group

          while current

            if (plan_id = current.plan_id)
              hash[group.id] << plan_id
              all_plan_ids << plan_id
            end

            current = groups_map[current.parent_id]
          end
        end

      # Grab all the plans for all the Groups, using only a single query.
      plans = Plan
        .where(id: all_plan_ids.to_a)
        .each_with_object({}) do |plan, hash|
          hash[plan.id] = plan
        end

      # Assign all the plans to the groups that have access to them.
      groups.each do |group|
        group.memoized_plans = plans_map[group.id].map { |id| plans[id] }
      end
    end

    # Returns an ActiveRecord::Relation that includes the given groups, and all
    # their (recursive) ancestors.
    def groups_and_ancestors_for(groups)
      Gitlab::GroupHierarchy
        .new(groups)
        .base_and_ancestors
        .select(:id, :parent_id, :plan_id)
    end
  end
end
