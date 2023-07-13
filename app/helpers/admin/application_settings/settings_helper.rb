# frozen_string_literal: true

module Admin
  module ApplicationSettings
    module SettingsHelper
      def inactive_projects_deletion_data(settings)
        {
          delete_inactive_projects: settings.delete_inactive_projects.to_s,
          inactive_projects_delete_after_months: settings.inactive_projects_delete_after_months,
          inactive_projects_min_size_mb: settings.inactive_projects_min_size_mb,
          inactive_projects_send_warning_email_after_months: settings.inactive_projects_send_warning_email_after_months
        }
      end

      def project_missing_pipeline_yaml?(project)
        project.repository&.gitlab_ci_yml.blank?
      end

      def code_suggestions_description
        link_start = code_suggestions_link_start(code_suggestions_docs_url)

        # rubocop:disable Layout/LineLength
        # rubocop:disable Style/FormatString
        s_('CodeSuggestionsSM|Enable Code Suggestions for users of this instance. %{link_start}What are Code Suggestions?%{link_end}')
          .html_safe % { link_start: link_start, link_end: '</a>'.html_safe }
        # rubocop:enable Style/FormatString
        # rubocop:enable Layout/LineLength
      end

      def code_suggestions_token_explanation
        link_start = code_suggestions_link_start(code_suggestions_pat_docs_url)

        # rubocop:disable Layout/LineLength
        # rubocop:disable Style/FormatString
        s_('CodeSuggestionsSM|On GitLab.com, create a token. This token is required to use Code Suggestions on your self-managed instance. %{link_start}How do I create a token?%{link_end}')
          .html_safe % { link_start: link_start, link_end: '</a>'.html_safe }
        # rubocop:enable Style/FormatString
        # rubocop:enable Layout/LineLength
      end

      def code_suggestions_agreement
        terms_link_start = code_suggestions_link_start(code_suggestions_agreement_url)
        ai_docs_link_start = code_suggestions_link_start(code_suggestions_ai_docs_url)

        # rubocop:disable Layout/LineLength
        # rubocop:disable Style/FormatString
        s_('CodeSuggestionsSM|By enabling this feature, you agree to the %{terms_link_start}GitLab Testing Agreement%{link_end} and acknowledge that GitLab will send data from the instance, including personal data, to our %{ai_docs_link_start}AI providers%{link_end} to provide this feature.')
          .html_safe % { terms_link_start: terms_link_start, ai_docs_link_start: ai_docs_link_start, link_end: '</a>'.html_safe }
        # rubocop:enable Style/FormatString
        # rubocop:enable Layout/LineLength
      end

      private

      # rubocop:disable Gitlab/DocUrl
      # We want to link SaaS docs for flexibility for every URL related to Code Suggestions on Self Managed.
      # We expect to update docs often during the Beta and we want to point user to the most up to date information.
      def code_suggestions_docs_url
        'https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html'
      end

      def code_suggestions_agreement_url
        'https://about.gitlab.com/handbook/legal/testing-agreement/'
      end

      def code_suggestions_ai_docs_url
        'https://docs.gitlab.com/ee/user/ai_features.html#third-party-services'
      end

      def code_suggestions_pat_docs_url
        'https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token'
      end
      # rubocop:enable Gitlab/DocUrl

      def code_suggestions_link_start(url)
        "<a href=\"#{url}\" target=\"_blank\" rel=\"noopener noreferrer\">".html_safe
      end
    end
  end
end
