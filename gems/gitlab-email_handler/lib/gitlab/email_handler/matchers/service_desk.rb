# frozen_string_literal: true

require_relative 'base'

module Gitlab
  module EmailHandler
    module Matchers
      # Mirrors Gitlab::Email::Handler::ServiceDeskHandler (parsing portion).
      #   incoming+gitlab-org-gitlab-ce-20-issue-@incoming.gitlab.com
      #   incoming+gitlab-org/gitlab-ce@incoming.gitlab.com (legacy)
      #   support+gitlab-org-gitlab-ce-abc123_def@service-desk.gitlab.com (project key)
      #
      # The opaque project key form (slug-key) is stored whole in
      # `service_desk_settings.project_key_address_slug` and claimed as unique
      # in the Topology Service, so it is identifiable without a database
      # lookup. Resolving which project it belongs to remains an app-side
      # concern (Project.with_service_desk_key). The custom email form is
      # resolvable via a Topology Service lookup.
      class ServiceDesk < Base
        HANDLER_REGEX = /\A#{ReplyKey::HANDLER_ACTION_BASE_REGEX}-issue-\z/
        HANDLER_REGEX_LEGACY = /\A(?<project_path>[^+]*)\z/
        # Parses an opaque service desk key of the form `<slug>-<key>`. The key
        # is resolved against the database (Project.with_service_desk_key) so
        # this stays an app-side concern, but the pattern itself lives here to
        # keep all email key parsing in one place.
        PROJECT_KEY_PATTERN = /\A(?<slug>.+)-(?<key>[a-z0-9_]+)\z/

        def match(mail_key)
          key = mail_key.to_s

          matched = HANDLER_REGEX.match(key) unless mail_key&.include?('/')
          if matched
            return identification(
              project_slug: matched[:project_slug],
              project_id: matched[:project_id]&.to_i
            )
          end

          matched = HANDLER_REGEX_LEGACY.match(key)
          if matched && can_handle_legacy_format?(matched[:project_path], key)
            return identification(project_path: matched[:project_path])
          end

          match_project_key(key)
        end

        def handler_name
          :service_desk
        end

        private

        def can_handle_legacy_format?(project_path, mail_key)
          project_path&.include?('/') && !mail_key.include?('+')
        end

        # An opaque `<slug>-<key>` project key. The whole concatenated string is
        # what `service_desk_settings.project_key_address_slug` stores and the
        # Topology Service claims, so no splitting is needed: both parts are
        # already lowercase by validation, and the composite value is matched
        # verbatim.
        def match_project_key(key)
          return unless PROJECT_KEY_PATTERN.match?(key)

          identification(project_key_address_slug: key)
        end
      end
    end
  end
end
