# NamespaceValidator
#
# Custom validator for GitLab namespace values.
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class NamespaceValidator < ActiveModel::EachValidator
  RESERVED = %w[
    .well-known
    admin
    all
    assets
    ci
    dashboard
    files
    groups
    help
    hooks
    issues
    merge_requests
    new
    notes
    profile
    projects
    public
    repository
    robots.txt
    s
    search
    services
    snippets
    teams
    u
    unsubscribes
    users
  ].freeze

  def self.valid?(value)
    !reserved?(value) && follow_format?(value)
  end

  def self.reserved?(value)
    RESERVED.include?(value)
  end

  def self.follow_format?(value)
    value =~ Gitlab::Regex.namespace_regex
  end

  delegate :reserved?, :follow_format?, to: :class

  def validate_each(record, attribute, value)
    unless follow_format?(value)
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
    end

    if reserved?(value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end
