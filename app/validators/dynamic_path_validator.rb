# DynamicPathValidator
#
# Custom validator for GitLab path values.
# These paths are assigned to `Namespace` (& `Group` as a subclass) & `Project`
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class DynamicPathValidator < ActiveModel::EachValidator
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
    -
    .well-known
    abuse_reports
    admin
    all
    api
    assets
    autocomplete
    ci
    dashboard
    explore
    files
    groups
    health_check
    help
    hooks
    import
    invites
    issues
    jwt
    koding
    member
    merge_requests
    new
    notes
    notification_settings
    oauth
    profile
    projects
    public
    repository
    robots.txt
    s
    search
    sent_notifications
    services
    snippets
    teams
    u
    unsubscribes
    uploads
    users
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
  WILDCARD_ROUTES = Set.new(%w[
    artifacts
    badges
    blame
    blob
    commits
    create
    create_dir
    edit
    environments/folders
    files
    find_file
    gitlab-lfs/objects
    info/lfs/objects
    logs_tree
    new
    preview
    raw
    tree
    update
    wikis
  ]).freeze

  STRICT_RESERVED = (TOP_LEVEL_ROUTES | WILDCARD_ROUTES).freeze

  def self.valid?(path)
    path_segments = path.split('/')

    !reserved?(path) && path_segments.all? { |value| follow_format?(value) }
  end

  def self.reserved?(path)
    path = path.to_s.downcase
    top_level, wildcard_part = path.split('/', 2)

    includes_reserved_top_level?(top_level) || includes_reserved_wildcard?(wildcard_part)
  end

  def self.includes_reserved_wildcard?(path)
    WILDCARD_ROUTES.any? do |reserved_word|
      contains_path_part?(path, reserved_word)
    end
  end

  def self.includes_reserved_top_level?(path)
    TOP_LEVEL_ROUTES.any? do |reserved_route|
      contains_path_part?(path, reserved_route)
    end
  end

  def self.contains_path_part?(path, part)
    path =~ %r{(/|\A)#{Regexp.quote(part)}(/|\z)}
  end

  def self.follow_format?(value)
    value =~ Gitlab::Regex.namespace_regex
  end

  delegate :reserved?, :follow_format?, to: :class

  def validate_each(record, attribute, value)
    unless follow_format?(value)
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
    end

    full_path = record.respond_to?(:full_path) ? record.full_path : value

    if reserved?(full_path)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end
