# frozen_string_literal: true

module OptimizedIssuableLabelFilter
  def by_label(items)
    return items unless params.labels?

    return super if Feature.disabled?(:optimized_issuable_label_filter)

    target_model = items.model

    if params.filter_by_no_label?
      items.where('NOT EXISTS (?)', optimized_any_label_query(target_model))
    elsif params.filter_by_any_label?
      items.where('EXISTS (?)', optimized_any_label_query(target_model))
    else
      issuables_with_selected_labels(items, target_model)
    end
  end

  # Taken from IssuableFinder
  def count_by_state
    return super if root_namespace.nil?
    return super if Feature.disabled?(:optimized_issuable_label_filter)

    count_params = params.merge(state: nil, sort: nil, force_cte: true)
    finder = self.class.new(current_user, count_params)

    state_counts = finder
      .execute
      .reorder(nil)
      .group(:state_id)
      .count

    counts = state_counts.transform_keys { |key| count_key(key) }

    counts[:all] = counts.values.sum
    counts.with_indifferent_access
  end

  private

  def issuables_with_selected_labels(items, target_model)
    if root_namespace
      all_label_ids = find_label_ids(root_namespace)
      # Found less labels in the DB than we were searching for. Return nothing.
      return items.none if all_label_ids.size != params.label_names.size

      all_label_ids.each do |label_ids|
        items = items.where('EXISTS (?)', optimized_label_query_by_label_ids(target_model, label_ids))
      end
    else
      params.label_names.each do |label_name|
        items = items.where('EXISTS (?)', optimized_label_query_by_label_name(target_model, label_name))
      end
    end

    items
  end

  def find_label_ids(root_namespace)
    finder_params = {
      include_subgroups: true,
      include_ancestor_groups: true,
      include_descendant_groups: true,
      group: root_namespace,
      title: params.label_names
    }

    LabelsFinder
      .new(nil, finder_params)
      .execute(skip_authorization: true)
      .pluck(:title, :id)
      .group_by(&:first)
      .values
      .map { |labels| labels.map(&:last) }
  end

  def root_namespace
    strong_memoize(:root_namespace) do
      (params.project || params.group)&.root_ancestor
    end
  end

  def optimized_any_label_query(target_model)
    LabelLink
      .where(target_type: target_model.name)
      .where(LabelLink.arel_table['target_id'].eq(target_model.arel_table['id']))
      .limit(1)
  end

  def optimized_label_query_by_label_ids(target_model, label_ids)
    LabelLink
      .where(target_type: target_model.name)
      .where(LabelLink.arel_table['target_id'].eq(target_model.arel_table['id']))
      .where(label_id: label_ids)
      .limit(1)
  end

  def optimized_label_query_by_label_name(target_model, label_name)
    LabelLink
      .joins(:label)
      .where(target_type: target_model.name)
      .where(LabelLink.arel_table['target_id'].eq(target_model.arel_table['id']))
      .where(labels: { name: label_name })
      .limit(1)
  end
end
