# frozen_string_literal: true

module FinderMethods
  # rubocop: disable CodeReuse/ActiveRecord
  def find_by!(...)
    raise_not_found_unless_authorized execute.reorder(nil).find_by!(...)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def find_by(...)
    if_authorized execute.reorder(nil).find_by(...)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def find(...)
    raise_not_found_unless_authorized execute.reorder(nil).find(...)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def raise_not_found_unless_authorized(result)
    result = if_authorized(result)

    unless result
      # This fetches the model from the `ActiveRecord::Relation` but does not
      # actually execute the query.
      model = execute.model
      raise ActiveRecord::RecordNotFound, "Couldn't find #{model}"
    end

    result
  end

  def if_authorized(result)
    # Return the result if the finder does not perform authorization checks.
    # this is currently the case in the `MilestoneFinder`
    return result unless respond_to?(:current_user, true)

    result if can_read_object?(result)
  end

  def can_read_object?(object)
    # When there's no policy, we'll allow the read, this is for example the case
    # for Todos
    return true unless DeclarativePolicy.has_policy?(object)

    Ability.allowed?(current_user, :"read_#{to_ability_name(object)}", object)
  end

  def to_ability_name(object)
    return object.to_ability_name if object.respond_to?(:to_ability_name)

    # Not all objects define `#to_ability_name`, so attempt to derive it:
    object.model_name.singular
  end
end
