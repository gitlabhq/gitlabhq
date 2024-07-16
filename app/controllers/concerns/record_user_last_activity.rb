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
    after_action :set_member_last_activity
  end

  def set_user_last_activity
    return unless request.get?
    return if Gitlab::Database.read_only?
    return unless current_user

    # TODO: add namespace & project - https://gitlab.com/gitlab-org/gitlab/-/issues/387952
    Users::ActivityService.new(author: current_user).execute
  end

  def set_member_last_activity
    context = @group || @project # rubocop:disable Gitlab/ModuleWithInstanceVariables -- This is a controller concern
    return unless current_user && context && context.persisted?

    Gitlab::EventStore.publish(
      Users::ActivityEvent.new(data: {
        user_id: current_user.id,
        namespace_id: context.root_ancestor.id
      })
    )
  end
end

RecordUserLastActivity.prepend_mod
