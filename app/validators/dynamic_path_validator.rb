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
  TOP_LEVEL_ROUTES = %w[
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
  ].freeze

  # This list should contain all words following `/*namespace_id/:project_id` in
  # routes that contain a second wildcard.
  #
  # Example:
  #   /*namespace_id/:project_id/badges/*ref/build
  #
  # If `badges` was allowed as a project/group name, we would not be able to access the
  # `badges` route for those projects:
  #
  # Consider a namespace with path `foo/bar` and a project called `badges`.
  # The route to the build badge would then be `/foo/bar/badges/badges/master/build.svg`
  #
  # When accessing this path the route would be matched to the `badges` path
  # with the following params:
  #   - namespace_id: `foo`
  #   - project_id: `bar`
  #   - ref: `badges/master`
  #
  # Failing to find the project, this would result in a 404.
  #
  # By rejecting `badges` the router can _count_ on the fact that `badges` will
  # be preceded by the `namespace/project`.
  WILDCARD_ROUTES = %w[
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
  ].freeze

  # These are all the paths that follow `/groups/*id/ or `/groups/*group_id`
  # We need to reject these because we have a `/groups/*id` page that is the same
  # as the `/*id`.
  #
  # If we would allow a subgroup to be created with the name `activity` then
  # this group would not be accessible through `/groups/parent/activity` since
  # this would map to the activity-page of it's parent.
  GROUP_ROUTES = %w[
    activity
    analytics
    audit_events
    avatar
    edit
    group_members
    hooks
    issues
    labels
    ldap
    ldap_group_links
    merge_requests
    milestones
    notification_setting
    pipeline_quota
    projects
    subgroups
  ].freeze

  CHILD_ROUTES = (WILDCARD_ROUTES | GROUP_ROUTES).freeze

  def self.without_reserved_wildcard_paths_regex
    @without_reserved_wildcard_paths_regex ||= regex_excluding_child_paths(WILDCARD_ROUTES)
  end

  def self.without_reserved_child_paths_regex
    @without_reserved_child_paths_regex ||= regex_excluding_child_paths(CHILD_ROUTES)
  end

  # This is used to validate a full path.
  # It doesn't match paths
  #   - Starting with one of the top level words
  #   - Containing one of the child level words in the middle of a path
  def self.regex_excluding_child_paths(child_routes)
    reserved_top_level_words = Regexp.union(TOP_LEVEL_ROUTES)
    not_starting_in_reserved_word = %r{\A/?(?!(#{reserved_top_level_words})(/|\z))}

    reserved_child_level_words = Regexp.union(child_routes)
    not_containing_reserved_child = %r{(?!\S+/(#{reserved_child_level_words})(/|\z))}

    %r{#{not_starting_in_reserved_word}
       #{not_containing_reserved_child}
       #{Gitlab::Regex.full_namespace_regex}}x
  end

  def self.valid?(path)
    path =~ Gitlab::Regex.full_namespace_regex && !full_path_reserved?(path)
  end

  def self.full_path_reserved?(path)
    path = path.to_s.downcase
    _project_part, namespace_parts = path.reverse.split('/', 2).map(&:reverse)

    wildcard_reserved?(path) || child_reserved?(namespace_parts)
  end

  def self.child_reserved?(path)
    return false unless path

    path !~ without_reserved_child_paths_regex
  end

  def self.wildcard_reserved?(path)
    return false unless path

    path !~ without_reserved_wildcard_paths_regex
  end

  delegate :full_path_reserved?,
           :child_reserved?,
           to: :class

  def path_reserved_for_record?(record, value)
    full_path = record.respond_to?(:full_path) ? record.full_path : value

    # For group paths the entire path cannot contain a reserved child word
    # The path doesn't contain the last `_project_part` so we need to validate
    # if the entire path.
    # Example:
    #   A *group* with full path `parent/activity` is reserved.
    #   A *project* with full path `parent/activity` is allowed.
    if record.is_a? Group
      child_reserved?(full_path)
    else
      full_path_reserved?(full_path)
    end
  end

  def validate_each(record, attribute, value)
    unless value =~ Gitlab::Regex.namespace_regex
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
      return
    end

    if path_reserved_for_record?(record, value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end
