# frozen_string_literal: true

module Gitlab
  module Observability
    extend self

    ACTION_TO_PERMISSION = {
      explore: :read_observability,
      datasources: :admin_observability,
      manage: :admin_observability,
      dashboards: :read_observability
    }.freeze

    EMBEDDABLE_PATHS = %w[explore goto].freeze

    # Returns the GitLab Observability URL
    #
    def observability_url
      return ENV['OVERRIDE_OBSERVABILITY_URL'] if ENV['OVERRIDE_OBSERVABILITY_URL']
      # TODO Make observability URL configurable https://gitlab.com/gitlab-org/opstrace/opstrace-ui/-/issues/80
      return 'https://observe.staging.gitlab.com' if Gitlab.staging?

      'https://observe.gitlab.com'
    end

    # Returns true if the Observability feature flag is enabled
    #
    def enabled?(group = nil)
      return Feature.enabled?(:observability_group_tab, group) if group

      Feature.enabled?(:observability_group_tab)
    end

    # Returns the embeddable Observability URL of a given URL
    #
    #  - Validates the URL
    #  - Checks that the path is embeddable
    #  - Converts the gitlab.com URL to observe.gitlab.com URL
    #
    # e.g.
    #
    #  from: gitlab.com/groups/GROUP_PATH/-/observability/explore?observability_path=/explore
    #  to observe.gitlab.com/-/GROUP_ID/explore
    #
    # Returns nil if the URL is not a valid Observability URL or the path is not embeddable
    #
    def embeddable_url(url)
      uri = validate_url(url, Gitlab.config.gitlab.url)
      return unless uri

      group = group_from_observability_url(url)
      return unless group

      parsed_query = CGI.parse(uri.query.to_s).transform_values(&:first).symbolize_keys
      observability_path = parsed_query[:observability_path]

      return build_full_url(group, observability_path, '/') if observability_path_embeddable?(observability_path)
    end

    # Returns true if the user is allowed to perform an action within a group
    #
    def allowed_for_action?(user, group, action)
      return false if action.nil?

      permission = ACTION_TO_PERMISSION.fetch(action.to_sym, :admin_observability)
      allowed?(user, group, permission)
    end

    # Returns true if the user has the specified permission within the group
    def allowed?(user, group, permission = :admin_observability)
      return false unless group && user

      observability_url.present? && Ability.allowed?(user, permission, group)
    end

    # Builds the full Observability URL given a certan group and path
    #
    # If unsanitized_observability_path is not valid or missing, fallbacks to fallback_path
    #
    def build_full_url(group, unsanitized_observability_path, fallback_path)
      return unless group

      # When running Observability UI in standalone mode (i.e. not backed by Observability Backend)
      # the group-id is not required. !!This is only used for local dev!!
      base_url = ENV['STANDALONE_OBSERVABILITY_UI'] == 'true' ? observability_url : "#{observability_url}/-/#{group.id}"

      sanitized_path = if unsanitized_observability_path && sanitize(unsanitized_observability_path) != ''
                         CGI.unescapeHTML(sanitize(unsanitized_observability_path))
                       else
                         fallback_path || '/'
                       end

      sanitized_path.prepend('/') if sanitized_path[0] != '/'

      "#{base_url}#{sanitized_path}"
    end

    private

    def validate_url(url, reference_url)
      uri = URI.parse(url)
      reference_uri = URI.parse(reference_url)

      return uri if uri.scheme == reference_uri.scheme &&
        uri.port == reference_uri.port &&
        uri.host.casecmp?(reference_uri.host)
    rescue URI::InvalidURIError
      nil
    end

    def link_sanitizer
      @link_sanitizer ||= Rails::Html::Sanitizer.safe_list_sanitizer.new
    end

    def sanitize(input)
      link_sanitizer.sanitize(input, {})&.html_safe
    end

    def group_from_observability_url(url)
      match = Rails.application.routes.recognize_path(url)

      return if match[:unmatched_route].present?
      return if match[:group_id].blank? || match[:action].blank? || match[:controller] != "groups/observability"

      group_path = match[:group_id]
      Group.find_by_full_path(group_path)
    rescue ActionController::RoutingError
      nil
    end

    def observability_path_embeddable?(observability_path)
      return false unless observability_path

      observability_path = observability_path[1..] if observability_path[0] == '/'

      parsed_observability_path = URI.parse(observability_path).path.split('/')

      base_path = parsed_observability_path[0]

      EMBEDDABLE_PATHS.include?(base_path)
    rescue URI::InvalidURIError
      false
    end
  end
end
