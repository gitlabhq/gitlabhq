# RefValidator
#
# Custom validator for Ref.
class RefValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless record.project.repository.branch_exists?(value)
      record.errors.add(attribute, " does not exist")
    end
  end
end
