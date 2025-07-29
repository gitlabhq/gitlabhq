# frozen_string_literal: true

module Integrations
  module Base
    module Linear
      extend ActiveSupport::Concern

      include Base::IssueTracker
      # TODO: Depends on https://gitlab.com/gitlab-org/gitlab-svgs/-/merge_requests/1219
      # include HasAvatar

      # Workspace keys in the URL must be between 3 and 32 characters long and
      # contain only lowercase letters, numbers, and hyphens.
      LINEAR_WORKSPACE_URI_REGEX = %r{\Ahttps://linear\.app/[a-z0-9\-]{3,32}/?\z}

      # References like FEAT-123.
      # The project key part is between one and 7 characters long and uppercase letters + digits
      LINEAR_ISSUE_REFERENCE = %r{\b(?<issue>[A-Z0-9]{1,7}-\d+)\b}

      class_methods do
        def title
          'Linear'
        end

        def description
          s_("LinearIntegration|Use Linear as this project's issue tracker.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/linear.md', description
          )
        end

        def to_param
          'linear'
        end

        def attribution_notice
          s_('LinearIntegration|The Linear logo is a trademark of Linear Orbit Inc. in the U.S. and other countries.')
        end
      end

      included do
        field :workspace_url,
          title: -> { s_('LinearIntegration|Workspace URL') },
          placeholder: -> { s_('LinearIntegration|https://linear.app/example') },
          help: -> { s_('LinearIntegration|Linear workspace URL (for example, https://linear.app/example)') },
          required: true

        with_options if: :activated? do
          validates :workspace_url, presence: true, public_url: true, format: {
            with: LINEAR_WORKSPACE_URI_REGEX,
            message: ->(_object, _data) { s_('LinearIntegration|URL must point to a workspace URL like https://linear.app/example') }
          }
        end

        def reference_pattern(*)
          @reference_pattern ||= LINEAR_ISSUE_REFERENCE
        end

        # Normally external issue trackers in GitLab save `project_url`, `issue_url` and `new_issue_url`
        # in a separate DB table, but for the Linear integration we just use the `encrypted_properties` column
        #
        # That's why we overwrite `supports_data_fields?` and `handle_properties`
        #
        # For Linear only the workspace url is needed and the rest of the URLs can be derived
        #
        def supports_data_fields?
          false
        end

        def handle_properties
          # no op
        end

        def project_url
          workspace_url
        end

        def issues_url
          @issues_url ||= Gitlab::Utils.append_path(workspace_url, '/issue/:id')
        end
      end
    end
  end
end
