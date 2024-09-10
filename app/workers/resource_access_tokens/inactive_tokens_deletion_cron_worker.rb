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

      User.project_bot.where('"users"."id" > ?', cursor || 0).each_batch(of: BATCH_SIZE) do |relation| # rubocop:disable CodeReuse/ActiveRecord -- each_batch
        initiate_users_deletion(
          relation.select(:id, :username).left_joins(:personal_access_tokens).where(personal_access_tokens: PersonalAccessToken.expired_before(cut_off).or(PersonalAccessToken.revoked_before(cut_off))).load # rubocop:disable CodeReuse/ActiveRecord -- each_batch
        )

        if runtime_limiter.over_time? # rubocop:disable Style/Next -- we must break iteration
          self.class.perform_in(2.minutes, relation.maximum(:id))

          break
        end
      end
    end

    private

    def initiate_users_deletion(users)
      return if users.empty?

      DeleteUserWorker.bulk_perform_async_with_contexts(
        users,
        arguments_proc: ->(user) { [admin_bot_id, user.id, { skip_authorization: true }] },
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
