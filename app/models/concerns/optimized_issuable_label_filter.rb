# frozen_string_literal: true

module OptimizedIssuableLabelFilter
  extend ActiveSupport::Concern

  prepended do
    extend Gitlab::Cache::RequestCache

    # Avoid repeating label queries times when the finder is instantiated multiple times during the request.
    request_cache(:find_label_ids) { [root_namespace.id, params.label_names] }
  end

  def by_label(items)
    return items unless params.labels?

    return super if Feature.disabled?(:optimized_issuable_label_filter, default_enabled: :yaml)

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
    return super if Feature.disabled?(:optimized_issuable_label_filter, default_enabled: :yaml)

    count_params = params.merge(state: nil, sort: nil, force_cte: true)
    finder = self.class.new(current_user, count_params)

    state_counts = finder
      .execute
      .reorder(nil)
      .group(:state_id)
      .count

    counts = Hash.new(0)

    state_counts.each do |key, value|
      counts[count_key(key)] += value
    end

    counts[:all] = counts.values.sum
    counts.with_indifferent_access
  end

  private

  def issuables_with_selected_labels(items, target_model)
    if root_namespace
      all_label_ids = find_label_ids
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

  def find_label_ids
    group_labels = Label
      .where(project_id: nil)
      .where(title: params.label_names)
      .where(group_id: root_namespace.self_and_descendants.select(:id))

    project_labels = Label
      .where(group_id: nil)
      .where(title: params.label_names)
      .where(project_id: Project.select(:id).where(namespace_id: root_namespace.self_and_descendants.select(:id)))

    Label
      .from_union([group_labels, project_labels], remove_duplicates: false)
      .reorder(nil)
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
