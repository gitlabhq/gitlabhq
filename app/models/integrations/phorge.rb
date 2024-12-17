# frozen_string_literal: true

module Integrations
  class Phorge < Integration
    include Base::IssueTracker
    include HasIssueTrackerFields
    include HasAvatar

    PHORGE_FIELDS = %w[project_url issues_url].freeze

    validates :project_url, :issues_url, presence: true, public_url: true, if: :activated?

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

    def self.help
      docs_link = ActionController::Base.helpers.link_to(
        '',
        Rails.application.routes.url_helpers.help_page_url('user/project/integrations/phorge.md'),
        target: '_blank',
        rel: 'noopener noreferrer'
      )
      tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

      safe_format(
        s_("IssueTracker|Use Phorge as this project's issue tracker. %{link_start}Learn more.%{link_end}"),
        tag_pair_docs_link
      )
    end

    def self.to_param
      'phorge'
    end

    def self.fields
      super.select { |field| PHORGE_FIELDS.include?(field.name) }
    end
  end
end
