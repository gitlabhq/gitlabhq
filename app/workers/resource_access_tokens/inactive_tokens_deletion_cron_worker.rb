# frozen_string_literal: true

module ResourceAccessTokens
  class InactiveTokensDeletionCronWorker
    include ApplicationWorker
    include CronjobQueue
    include Gitlab::Utils::StrongMemoize

    idempotent!
    data_consistency :sticky
    feature_category :system_access

    BATCH_SIZE = 1000
    MAX_RUNTIME = 3.minutes

    def perform(cursor = nil)
      runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)

      # rubocop:disable CodeReuse/ActiveRecord -- each_batch
      User.project_bot.where('"users"."id" > ?', cursor || 0).each_batch(of: BATCH_SIZE) do |relation|
        project_bot_users_whose_all_tokens_became_inactive_before_cut_off_date_or_without_tokens =
          relation
            # uncomment this line to optimize SELECT after delete_inactive_project_bot_users FF is removed
            # .select(:id, :username)
            .where(
              'NOT EXISTS (?)',
              PersonalAccessToken
                .select(1)
                .where('"personal_access_tokens"."user_id" = "users"."id"')
                .and(
                  PersonalAccessToken.expired_before(cut_off).or(PersonalAccessToken.revoked_before(cut_off))
                    .invert_where
                )
            )

        if Feature.enabled?(:delete_inactive_project_bot_users) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- cron worker without actor
          initiate_deletion_for(
            project_bot_users_whose_all_tokens_became_inactive_before_cut_off_date_or_without_tokens
          )
        else
          project_bot_users_whose_all_tokens_became_inactive_before_cut_off_date_or_without_tokens.each do |user|
            next if user.blocked?

            user.update(
              note: "This project_bot user was blocked because it has no active token assigned. " \
                "Related to a feature rollout https://gitlab.com/gitlab-org/gitlab/-/issues/471683. #{user.note}"
            )

            user.block

            Gitlab::AppLogger.info(
              class: self.class.name,
              user_id: user.id,
              username: user.username,
              message: "Blocked the project_bot user because it has no active token assigned"
            )
          end
        end

        if runtime_limiter.over_time? # rubocop:disable Style/Next -- we must break iteration
          self.class.perform_in(2.minutes, relation.maximum(:id))

          break
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord -- each_batch
    end

    private

    def initiate_deletion_for(users)
      return if users.empty?

      DeleteUserWorker.bulk_perform_async_with_contexts(
        users,
        arguments_proc: ->(user) {
                          [
                            admin_bot_id, user.id,
                            { skip_authorization: true, reason_for_deletion: "No active token assigned" }
                          ]
                        },
        context_proc: ->(user) { { user: user } }
      )
    end

    def cut_off
      ApplicationSetting::INACTIVE_RESOURCE_ACCESS_TOKENS_DELETE_AFTER_DAYS.days.ago
    end

    def admin_bot_id
      Users::Internal.admin_bot.id
    end
    strong_memoize_attr :admin_bot_id
  end
end
