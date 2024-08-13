# frozen_string_literal: true

# Override ActiveRecord::Enum.load_schema! to remove the check that verifies that
# defined enum attributes are backed by a database column.
#
# The check has been introduced in Rails 7.1: https://github.com/rails/rails/pull/45734
#
# However, there are valid use cases when the enum definition should not raise an error
# when the column does not exist in the column list:
#
# - Perform database migration on a particular version, the one that doesn't contain the column
# - Try performing another operation that loads Rails environment (for example, another migration):
#   - Rails environment is being initialized and configured
#   - Gitlab::CurrentSetting is being called to customize the configuration
#   - ApplicationSetting model tries to define a enum attribute that is not backed by a column on that patricular
#   migration version
#   - An error is raised

module ActiveRecordAttributesPatch
  def attribute(name, *args, **options)
    return super unless defined_enums.key?(name)
    return unless block_given?

    super do |subtype|
      subtype = subtype.subtype if ActiveRecord::Enum::EnumType === subtype
      ActiveRecord::Enum::EnumType.new(name, defined_enums[name], subtype)
    end
  end
end

ActiveRecord::Attributes::ClassMethods.prepend(ActiveRecordAttributesPatch)
