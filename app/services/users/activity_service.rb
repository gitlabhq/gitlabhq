# frozen_string_literal: true

module Users
  class ActivityService
    LEASE_TIMEOUT = 1.minute.to_i

    def initialize(author, activity)
      @user = if author.respond_to?(:username)
                author
              elsif author.respond_to?(:user)
                author.user
              end

      @activity = activity
    end

    def execute
      return unless @user

      record_activity
    end

    private

    def record_activity
      return if Gitlab::Database.read_only?

      lease = Gitlab::ExclusiveLease.new("acitvity_service:#{@user.id}",
                                         timeout: LEASE_TIMEOUT)
      return unless lease.try_obtain

      @user.update_attribute(:last_activity_on, Date.today)
      Rails.logger.debug("Recorded activity: #{@activity} for User ID: #{@user.id} (username: #{@user.username})")
    end
  end
end
