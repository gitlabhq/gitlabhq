# frozen_string_literal: true

module UpdatedAtFilter
  def by_updated_at(items)
    updated_before = params[:updated_before]&.in_time_zone
    updated_after = params[:updated_after]&.in_time_zone
    return items.none if [updated_before, updated_after].all?(&:present?) && updated_before < updated_after

    items = items.updated_before(updated_before) if updated_before.present?
    items = items.updated_after(updated_after) if updated_after.present?

    items
  end
end
