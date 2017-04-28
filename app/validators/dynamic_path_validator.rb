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
    unicorn_test
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
    badges
    blame
    blob
    builds
    commits
    create
    create_dir
    edit
    environments/folders
    files
    find_file
    gitlab-lfs/objects
    info/lfs/objects
    new
    preview
    raw
    refs
    tree
    update
    wikis
  ]).freeze

  # These are all the paths that follow `/groups/*id/ or `/groups/*group_id`
  # We need to reject these because we have a `/groups/*id` page that is the same
  # as the `/*id`.
  #
  # If we would allow a subgroup to be created with the name `activity` then
  # this group would not be accessible through `/groups/parent/activity` since
  # this would map to the activity-page of it's parent.
  GROUP_ROUTES = Set.new(%w[
    activity
    avatar
    edit
    group_members
    issues
    labels
    merge_requests
    milestones
    projects
    subgroups
  ])

  CHILD_ROUTES = (WILDCARD_ROUTES | GROUP_ROUTES).freeze

  def self.without_reserved_wildcard_paths_regex
    @full_path_without_wildcard_regex ||= regex_excluding_child_paths(WILDCARD_ROUTES)
  end

  def self.without_reserved_child_paths_regex
    @full_path_without_child_routes_regex ||= regex_excluding_child_paths(CHILD_ROUTES)
  end

  # This is used to validate a full path.
  # It doesn't match paths
  #   - Starting with one of the top level words
  #   - Containing one of the child level words in the middle of a path
  def self.regex_excluding_child_paths(child_routes)
    reserved_top_level_words = Regexp.union(TOP_LEVEL_ROUTES.to_a)
    not_starting_in_reserved_word = %r{^(/?)(?!(#{reserved_top_level_words})(/|$))}

    reserved_child_level_words = Regexp.union(child_routes.to_a)
    not_containing_reserved_child = %r{(?!(\S+)/(#{reserved_child_level_words})(/|$))}

    @full_path_regex = %r{
      #{not_starting_in_reserved_word}
      #{not_containing_reserved_child}
      #{Gitlab::Regex::FULL_NAMESPACE_REGEX_STR}}x
  end

  def self.valid?(path)
    path_segments = path.split('/')

    !reserved?(path) && path_segments.all? { |value| follow_format?(value) }
  end

  def self.reserved?(path)
    path = path.to_s.downcase
    _project_parts, namespace_parts = path.reverse.split('/', 2).map(&:reverse)

    wildcard_reserved?(path) || any_reserved?(namespace_parts)
  end

  def self.any_reserved?(path)
    return false unless path

    path !~ without_reserved_child_paths_regex
  end

  def self.wildcard_reserved?(path)
    return false unless path

    path !~ without_reserved_wildcard_paths_regex
  end

  def self.follow_format?(value)
    value =~ Gitlab::Regex.namespace_regex
  end

  delegate :reserved?,
           :any_reserved?,
           :follow_format?, to: :class

  def valid_full_path?(record, value)
    full_path = record.respond_to?(:full_path) ? record.full_path : value

    case record
    when Project || User
      reserved?(full_path)
    else
      any_reserved?(full_path)
    end
  end

  def validate_each(record, attribute, value)
    unless follow_format?(value)
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
    end

    if valid_full_path?(record, value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end
