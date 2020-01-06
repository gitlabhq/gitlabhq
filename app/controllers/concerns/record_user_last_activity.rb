# frozen_string_literal: true

# == RecordUserLastActivity
#
# Controller concern that updates the `last_activity_on` field of `users`
# for any authenticated GET request. The DB update will only happen once per day.
#
# In order to determine if you should include this concern or not, please check the
# description and discussion on this issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/54947
module RecordUserLastActivity
  include CookiesHelper
  extend ActiveSupport::Concern

  included do
    before_action :set_user_last_activity
  end

  def set_user_last_activity
    return unless request.get?
    return unless Feature.enabled?(:set_user_last_activity, default_enabled: true)
    return if Gitlab::Database.read_only?

    if current_user && current_user.last_activity_on != Date.today
      Users::ActivityService.new(current_user).execute
    end
  end
end
