# NamespaceValidator
#
# Custom validator for GitLab namespace values.
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class NamespaceValidator < ActiveModel::EachValidator
  RESERVED = %w(
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
    s
    search
    services
    snippets
    teams
    u
    unsubscribes
    users
  ).freeze

  def validate_each(record, attribute, value)
    unless value =~ Gitlab::Regex.namespace_regex
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
    end

    if reserved?(value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end

  private

  def reserved?(value)
    RESERVED.include?(value)
  end
end
