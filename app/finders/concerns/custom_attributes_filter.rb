# frozen_string_literal: true

module CustomAttributesFilter
  # rubocop: disable CodeReuse/ActiveRecord
  def by_custom_attributes(items)
    return items unless params[:custom_attributes].is_a?(Hash)
    return items unless Ability.allowed?(current_user, :read_custom_attribute)

    association = items.reflect_on_association(:custom_attributes)
    attributes_table = association.klass.arel_table
    attributable_table = items.model.arel_table

    custom_attributes = association.klass.select('true').where(
      attributes_table[association.foreign_key]
        .eq(attributable_table[association.association_primary_key])
    )

    # perform a subquery for each attribute to be filtered
    params[:custom_attributes].inject(items) do |scope, (key, value)|
      scope.where('EXISTS (?)', custom_attributes.where(key: key, value: value))
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
