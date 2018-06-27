class TopLevelGroupValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value&.subgroup?
      record.errors.add(attribute, "must be a top level Group")
    end
  end
end
