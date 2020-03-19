# frozen_string_literal: true

module HasUniqueInternalUsers
  extend ActiveSupport::Concern

  class_methods do
    private

    def unique_internal(scope, username, email_pattern, &block)
      scope.first || create_unique_internal(scope, username, email_pattern, &block)
    end

    def create_unique_internal(scope, username, email_pattern, &creation_block)
      # Since we only want a single one of these in an instance, we use an
      # exclusive lease to ensure than this block is never run concurrently.
      lease_key = "user:unique_internal:#{username}"
      lease = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute.to_i)

      until uuid = lease.try_obtain
        # Keep trying until we obtain the lease. To prevent hammering Redis too
        # much we'll wait for a bit between retries.
        sleep(1)
      end

      # Recheck if the user is already present. One might have been
      # added between the time we last checked (first line of this method)
      # and the time we acquired the lock.
      existing_user = uncached { scope.first }
      return existing_user if existing_user.present?

      uniquify = Uniquify.new

      username = uniquify.string(username) { |s| User.find_by_username(s) }

      email = uniquify.string(-> (n) { Kernel.sprintf(email_pattern, n) }) do |s|
        User.find_by_email(s)
      end

      user = scope.build(
        username: username,
        email: email,
        &creation_block
      )

      Users::UpdateService.new(user, user: user).execute(validate: false)
      user
    ensure
      Gitlab::ExclusiveLease.cancel(lease_key, uuid)
    end
  end
end
