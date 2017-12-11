module EE
  module Issue
    extend ::Gitlab::Utils::Override

    # override
    def check_for_spam?
      author.support_bot? || super
    end

    # override
    def allows_multiple_assignees?
      project.feature_available?(:multiple_issue_assignees)
    end

    # override
    def subscribed_without_subscriptions?(user, *)
      # TODO: this really shouldn't be necessary, because the support
      # bot should be a participant (which is what the superclass
      # method checks for). However, the support bot gets filtered out
      # at the end of Participable#raw_participants as not being able
      # to read the project. Overriding *that* behavior is problematic
      # because it doesn't use the Policy framework, and instead uses a
      # custom-coded Ability.users_that_can_read_project, which is...
      # a pain to override in EE. So... here we say, the support bot
      # is subscribed by default, until an unsubscribed record appears,
      # even though it's not *technically* a participant in this issue.

      # Making the support bot subscribed to every issue is not as bad as it
      # seems, though, since it isn't permitted to :receive_notifications,
      # and doesn't actually show up in the participants list.
      user.support_bot? || super
    end

    # override
    def weight
      super if supports_weight?
    end

    # The functionality here is duplicated from the `IssuePolicy` and the
    # `EE::IssuePolicy` for better performace
    #
    # Make sure to keep this in sync with the policies.
    override :readable_by?
    def readable_by?(user)
      return super if user.full_private_access?

      super && ::EE::Gitlab::ExternalAuthorization
                 .access_allowed?(user, project.external_authorization_classification_label)
    end

    override :publicly_visible?
    def publicly_visible?
      super && !::EE::Gitlab::ExternalAuthorization.enabled?
    end

    def supports_weight?
      project&.feature_available?(:issue_weights)
    end
  end
end
