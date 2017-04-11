# NamespaceValidator
#
# Custom validator for GitLab namespace values.
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class NamespaceValidator < ActiveModel::EachValidator
  # All routes that appear on the top level must be listed here.
  # This will make sure that groups cannot be created with these names
  # as these routes would be masked by the paths already in place.
  #
  # Example:
  #   /api/api-project
  #
  #  the path `api` shouldn't be allowed because it would be masked by `api/*`
  #
  TOP_LEVEL_ROUTES = Set.new(%w[
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
    api
    autocomplete
    search
    member
    explore
    uploads
    import
    notification_settings
    abuse_reports
    invites
    help
    koding
    health_check
    jwt
    oauth
    sent_notifications
  ]).freeze

  # All project routes with wildcard argument must be listed here.
  # Otherwise it can lead to routing issues when route considered as project name.
  #
  # Example:
  #  /group/project/tree/deploy_keys
  #
  #  without tree as reserved name routing can match 'group/project' as group name,
  #  'tree' as project name and 'deploy_keys' as route.
  #

  WILDCARD_ROUTES = Set.new(%w[tree commits wikis new edit create update logs_tree
                               preview blob blame raw files create_dir find_file
                               artifacts graphs refs badges objects folders file])

  STRICT_RESERVED = (TOP_LEVEL_ROUTES | WILDCARD_ROUTES)

  def self.valid_full_path?(full_path)
    path_segments = full_path.split('/')
    root_segment = path_segments.shift

    valid?(root_segment, type: :top_level) && valid_wildcard_segments?(path_segments)
  end

  def self.valid_wildcard_segments?(segments)
    segments.all? { |segment| valid?(segment, type: :wildcard) }
  end

  def self.valid?(value, type: :strict)
    !reserved?(value, type: type) && follow_format?(value)
  end

  def self.reserved?(value, type: :strict)
    case type
    when :wildcard
      WILDCARD_ROUTES.include?(value)
    when :top_level
      TOP_LEVEL_ROUTES.include?(value)
    else
      STRICT_RESERVED.include?(value)
    end
  end

  def self.follow_format?(value)
    value =~ Gitlab::Regex.namespace_regex
  end

  delegate :reserved?, :follow_format?, to: :class

  def validate_each(record, attribute, value)
    unless follow_format?(value)
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
    end

    if reserved?(value, type: validation_type(record))
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end

  def validation_type(record)
    case record
    when Group
      record.parent_id ? :wildcard : :top_level
    when Project
      :wildcard
    else
      :strict
    end
  end
end
