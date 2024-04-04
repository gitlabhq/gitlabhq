# frozen_string_literal: true

module Integrations
  class Phorge < BaseIssueTracker
    include HasIssueTrackerFields

    validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

    # See https://we.phorge.it/source/phorge/browse/master/src/infrastructure/markup/rule/PhabricatorObjectRemarkupRule.php
    # for a canonical source of the regular expression used to parse Phorge
    # object references.
    #
    # > The "(?<![#@-])" prevents us from linking "#abcdef" or similar, and
    # > "ABC-T1" (see T5714), and from matching "@T1" as a task (it is a user)
    # > (see T9479).
    #
    # Note that object references in Phorge are prefixed with letters unique
    # to their underlying application, so T123 (a Maniphest task) is
    # distinct from D123 (a Differential patch). Keeping the T as part of
    # the task ID is appropriate here as it leaves room for expanding
    # reference parsing/linking to other types of Phorge entities.
    #
    # Also note, a prefix of # is being allowed here due to: 1) an assumed
    # likelihood of use; and b) lack of collision with native GitLab issues
    # since all Phorge identifiers have the application specific alpha prefix.
    def reference_pattern(*)
      @reference_pattern ||= /\b(?<![@-])(?<issue>T\d+)\b/
    end

    def self.title
      'Phorge'
    end

    def self.description
      s_("IssueTracker|Use Phorge as this project's issue tracker.")
    end

    # rubocop:disable Rails/OutputSafety -- It is fine to call html_safe here
    def self.help
      docs_link = ActionController::Base.helpers.link_to _('Learn more.'),
        Rails.application.routes.url_helpers.help_page_url('user/project/integrations/phorge'),
        target: '_blank',
        rel: 'noopener noreferrer'

      # rubocop:disable Gitlab/Rails/SafeFormat -- See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145863#note_1845580057
      format(
        s_("IssueTracker|Use Phorge as this project's issue tracker. %{docs_link}").html_safe,
        docs_link: docs_link.html_safe
      )
      # rubocop:enable Gitlab/Rails/SafeFormat
    end
    # rubocop:enable Rails/OutputSafety

    def self.to_param
      'phorge'
    end
  end
end
