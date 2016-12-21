# ProjectPathValidator
#
# Custom validator for GitLab project path values.
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class ProjectPathValidator < ActiveModel::EachValidator
  # All project routes with wildcard argument must be listed here.
  # Otherwise it can lead to routing issues when route considered as project name.
  #
  # Example:
  #  /group/project/tree/deploy_keys
  #
  #  without tree as reserved name routing can match 'group/project' as group name,
  #  'tree' as project name and 'deploy_keys' as route.
  #
  RESERVED = (NamespaceValidator::RESERVED -
              %w[dashboard help ci admin search] +
              %w[tree commits wikis new edit create update logs_tree
                 preview blob blame raw files create_dir find_file]).freeze

  def self.valid?(value)
    !reserved?(value)
  end

  def self.reserved?(value)
    RESERVED.include?(value)
  end

  delegate :reserved?, to: :class

  def validate_each(record, attribute, value)
    if reserved?(value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end
