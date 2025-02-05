# frozen_string_literal: true

module Users
  class Internal
    class << self
      include Gitlab::Utils::StrongMemoize
      # rubocop:disable CodeReuse/ActiveRecord

      # Return (create if necessary) the ghost user. The ghost user
      # owns records previously belonging to deleted users.
      def ghost
        email = 'ghost%s@example.com'
        unique_internal(User.where(user_type: :ghost), 'ghost', email) do |u|
          u.bio = _('This is a "Ghost User", created to hold all issues authored by users that have ' \
                    'since been deleted. This user cannot be removed.')
          u.name = 'Ghost User'
        end
      end

      def alert_bot
        email_pattern = "alert%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :alert_bot), 'alert-bot', email_pattern) do |u|
          u.bio = 'The GitLab alert bot'
          u.name = 'GitLab Alert Bot'
          u.avatar = bot_avatar(image: 'alert-bot.png')
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      def migration_bot
        email_pattern = "noreply+gitlab-migration-bot%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :migration_bot), 'migration-bot', email_pattern) do |u|
          u.bio = 'The GitLab migration bot'
          u.name = 'GitLab Migration Bot'
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      def security_bot
        email_pattern = "security-bot%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :security_bot), 'GitLab-Security-Bot', email_pattern) do |u|
          u.bio = 'System bot that monitors detected vulnerabilities for solutions ' \
                  'and creates merge requests with the fixes.'
          u.name = 'GitLab Security Bot'
          u.avatar = bot_avatar(image: 'security-bot.png')
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      def support_bot
        email_pattern = "support%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :support_bot), 'support-bot', email_pattern) do |u|
          u.bio = 'The GitLab support bot used for Service Desk'
          u.name = 'GitLab Support Bot'
          u.avatar = bot_avatar(image: 'support-bot.png')
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      # Checks against this bot are now included in every issue and work item
      # detail and list page rendering and in GraphQL queries (especially for determining
      # the web_url of an issue/work item).
      # Because the bot never changes once created, we can memoize it for
      # the lifetime of the application process. It also doesn't matter that
      # different nodes may have different object instances of the bot.
      # We only memoize the id because this is the information we check against.
      def support_bot_id
        support_bot.id
      end
      strong_memoize_attr :support_bot_id

      def automation_bot
        email_pattern = "automation%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :automation_bot), 'automation-bot', email_pattern) do |u|
          u.bio = 'The GitLab automation bot used for automated workflows and tasks'
          u.name = 'GitLab Automation Bot'
          u.avatar = bot_avatar(image: 'support-bot.png') # todo: add an avatar for automation-bot
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      def llm_bot
        email_pattern = "llm-bot%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :llm_bot), 'GitLab-Llm-Bot', email_pattern) do |u|
          u.bio = 'The Gitlab LLM bot used for fetching LLM-generated content'
          u.name = 'GitLab LLM Bot'
          u.avatar = bot_avatar(image: 'support-bot.png') # todo: add an avatar for llm-bot
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      def duo_code_review_bot
        email_pattern = "gitlab-duo%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :duo_code_review_bot), 'GitLabDuo', email_pattern) do |u|
          u.bio = 'GitLab Duo bot for handling AI tasks'
          u.name = 'GitLab Duo'
          u.avatar = bot_avatar(image: 'duo-bot.png')
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      def admin_bot
        email_pattern = "admin-bot%s@#{Settings.gitlab.host}"

        unique_internal(User.where(user_type: :admin_bot), 'GitLab-Admin-Bot', email_pattern) do |u|
          u.bio = 'Admin bot used for tasks that require admin privileges'
          u.name = 'GitLab Admin Bot'
          u.avatar = bot_avatar(image: 'admin-bot.png')
          u.admin = true
          u.confirmed_at = Time.zone.now
          u.private_profile = true
        end
      end

      # rubocop:enable CodeReuse/ActiveRecord

      def bot_avatar(image:)
        Rails.root.join('lib', 'assets', 'images', 'bot_avatars', image).open
      end

      private

      # NOTE: This method is patched in spec/spec_helper.rb to allow use of exclusive lease in RSpec's
      # :before_all scope to keep the specs DRY.
      def unique_internal(scope, username, email_pattern, &block)
        scope.first || create_unique_internal(scope, username, email_pattern, &block)
      end

      def create_unique_internal(scope, username, email_pattern, &creation_block)
        # Since we only want a single one of these in an instance, we use an
        # exclusive lease to ensure than this block is never run concurrently.
        lease_key = "user:unique_internal:#{username}"
        lease = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute.to_i)

        uuid = lease.try_obtain
        until uuid.present?
          # Keep trying until we obtain the lease. To prevent hammering Redis too
          # much we'll wait for a bit between retries.
          sleep(1)
          uuid = lease.try_obtain
        end

        # Recheck if the user is already present. One might have been
        # added between the time we last checked (first line of this method)
        # and the time we acquired the lock.
        existing_user = scope.model.uncached { scope.first }
        return existing_user if existing_user.present?

        uniquify = Gitlab::Utils::Uniquify.new

        username = uniquify.string(username) { |s| Namespace.by_path(s) }

        email = uniquify.string(->(n) { Kernel.sprintf(email_pattern, n) }) do |s|
          User.find_by_email(s)
        end

        user = scope.build(
          username: username,
          email: email,
          &creation_block
        )

        # https://gitlab.com/gitlab-org/gitlab/-/issues/442780
        organization = ::Organizations::Organization.first
        user.assign_personal_namespace(organization)
        user.organizations << organization

        Users::UpdateService.new(user, user: user).execute(validate: false)
        user
      ensure
        Gitlab::ExclusiveLease.cancel(lease_key, uuid)
      end
    end
  end
end

Users::Internal.prepend_mod
