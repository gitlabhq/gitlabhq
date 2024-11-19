# frozen_string_literal: true

module Issuables
  class LabelFilter < BaseFilter
    include Gitlab::Utils::StrongMemoize
    extend Gitlab::Cache::RequestCache

    def initialize(project:, group:, **kwargs)
      @project = project
      @group = group

      super(**kwargs)
    end

    def filter(issuables)
      filtered = by_label(issuables)
      filtered = by_label_union(filtered)
      by_negated_label(filtered)
    end

    def label_names_excluded_from_priority_sort
      label_names_from_params
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def label_link_query(issuables, label_ids: nil, label_names: nil)
      target_model = issuables.klass
      base_target_model = issuables.base_class

      # passing the original target_model just to avoid running the labels union query on group level issues pages
      # as the query becomes more expensive at group level. This is to be removed altogether as we migrate labels off
      # Epic altogether, planned as a high priority follow-up for Epic to WorkItem migration:
      # re https://gitlab.com/gitlab-org/gitlab/-/issues/465725
      relation = target_label_links_query(target_model, base_target_model, label_ids)
      relation = relation.joins(:label).where(labels: { name: label_names }) if label_names

      relation
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    attr_reader :project, :group

    # rubocop: disable CodeReuse/ActiveRecord
    def by_label(issuables)
      return issuables unless label_names_from_params.present?

      if filter_by_no_label?
        issuables.where(label_link_query(issuables).arel.exists.not)
      elsif filter_by_any_label?
        issuables.where(label_link_query(issuables).arel.exists)
      else
        issuables_with_selected_labels(issuables, label_names_from_params)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def by_label_union(issuables)
      return issuables unless label_names_from_or_params.present?

      if root_namespace
        all_label_ids = find_label_ids(label_names_from_or_params).flatten
        issuables.where(label_link_query(issuables, label_ids: all_label_ids).arel.exists)
      else
        issuables.where(label_link_query(issuables, label_names: label_names_from_or_params).arel.exists)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def by_negated_label(issuables)
      return issuables unless label_names_from_not_params.present?

      issuables_without_selected_labels(issuables, label_names_from_not_params)
    end

    def filter_by_no_label?
      label_names_from_params.map(&:downcase).include?(FILTER_NONE)
    end

    def filter_by_any_label?
      label_names_from_params.map(&:downcase).include?(FILTER_ANY)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def issuables_with_selected_labels(issuables, label_names)
      if root_namespace
        all_label_ids = find_label_ids(label_names)
        # Found less labels in the DB than we were searching for. Return nothing.
        return issuables.none if all_label_ids.size != label_names.size

        all_label_ids.each do |label_ids|
          issuables = issuables.where(label_link_query(issuables, label_ids: label_ids).arel.exists)
        end
      else
        label_names.each do |label_name|
          issuables = issuables.where(label_link_query(issuables, label_names: label_name).arel.exists)
        end
      end

      issuables
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def issuables_without_selected_labels(issuables, label_names)
      if root_namespace
        label_ids = find_label_ids(label_names).flatten(1)

        return issuables if label_ids.empty?

        issuables.where(label_link_query(issuables, label_ids: label_ids).arel.exists.not)
      else
        issuables.where(label_link_query(issuables, label_names: label_names).arel.exists.not)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_label_ids(label_names)
      find_label_ids_uncached(label_names)
    end
    # Avoid repeating label queries times when the finder is instantiated multiple times during the request.
    request_cache(:find_label_ids) { root_namespace.id }

    # This returns an array of label IDs per label name. It is possible for a label name
    # to have multiple IDs because we allow labels with the same name if they are on a different
    # project or group.
    #
    # For example, if we pass in `['bug', 'feature']`, this will return something like:
    # `[ [1, 2], [3] ]`
    #
    # rubocop: disable CodeReuse/ActiveRecord
    def find_label_ids_uncached(label_names)
      return [] if label_names.empty?

      group_labels = group_labels_for_root_namespace.where(title: label_names)
      project_labels = project_labels_for_root_namespace.where(title: label_names)

      Label
        .from_union([group_labels, project_labels], remove_duplicates: false)
        .reorder(nil)
        .pluck(:title, :id)
        .group_by(&:first)
        .values
        .map { |labels| labels.map(&:last) }
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def group_labels_for_root_namespace
      Label.where(project_id: nil).where(group_id: root_namespace.self_and_descendant_ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def project_labels_for_root_namespace
      Label.where(group_id: nil)
           .where(project_id: Project.select(:id).where(namespace_id: root_namespace.self_and_descendant_ids))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # overridden in EE
    def target_label_links_query(_target_model, base_target_model, label_ids)
      LabelLink.by_target_for_exists_query(base_target_model.name, base_target_model.arel_table['id'], label_ids)
    end

    def label_names_from_params
      return if params[:label_name].blank?

      strong_memoize(:label_names_from_params) do
        split_label_names(params[:label_name])
      end
    end

    def label_names_from_or_params
      return if or_params.blank? || or_params[:label_name].blank?

      strong_memoize(:label_names_from_or_params) do
        split_label_names(or_params[:label_name])
      end
    end

    def label_names_from_not_params
      return if not_params.blank? || not_params[:label_name].blank?

      strong_memoize(:label_names_from_not_params) do
        split_label_names(not_params[:label_name])
      end
    end

    def split_label_names(label_name_param)
      label_name_param.is_a?(String) ? label_name_param.split(',') : label_name_param
    end

    def root_namespace
      strong_memoize(:root_namespace) do
        (@project || @group)&.root_ancestor
      end
    end
  end
end

Issuables::LabelFilter.prepend_mod
