# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class Base
      def initialize(*)
        raise 'abstract'
      end

      def build!
        raise 'abstract'
      end

      def filter!
        recipients.select!(&:notifiable?)
      end

      def acting_user
        current_user
      end

      def target
        raise 'abstract'
      end

      # override if needed
      def recipients_target
        target
      end

      def project
        target.project
      end

      def group
        project&.group || target.try(:group)
      end

      def recipients
        @recipients ||= []
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def add_recipients(users, type, reason)
        if users.is_a?(ActiveRecord::Relation)
          users = users.includes(:notification_settings)
        end

        users = Array(users).compact
        recipients.concat(users.map { |u| make_recipient(u, type, reason) })
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def user_scope
        User.includes(:notification_settings)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def make_recipient(user, type, reason)
        NotificationRecipient.new(
          user, type,
          reason: reason,
          project: project,
          group: group,
          custom_action: custom_action,
          target: recipients_target,
          acting_user: acting_user
        )
      end

      def notification_recipients
        @notification_recipients ||=
          begin
            build!
            filter!
            recipients = self.recipients.sort_by { |r| NotificationReason.priority(r.reason) }.uniq(&:user)
            recipients.freeze
          end
      end

      def custom_action
        nil
      end

      protected

      def add_participants(user)
        return unless target.respond_to?(:participants)

        add_recipients(target.participants(user), :participating, nil)
      end

      def add_mentions(user, target:)
        return unless target.respond_to?(:mentioned_users)

        add_recipients(target.mentioned_users(user), :mention, NotificationReason::MENTIONED)
      end

      # Get project/group users with CUSTOM notification level
      # rubocop: disable CodeReuse/ActiveRecord
      def add_custom_notifications
        user_ids = []

        # Users with a notification setting on group or project
        user_ids += user_ids_notifiable_on(project, :custom)
        user_ids += user_ids_notifiable_on(group, :custom)

        # Users with global level custom
        user_ids_with_project_level_global = user_ids_notifiable_on(project, :global)
        user_ids_with_group_level_global   = user_ids_notifiable_on(group, :global)

        global_users_ids = user_ids_with_project_level_global.concat(user_ids_with_group_level_global)
        user_ids += user_ids_with_global_level_custom(global_users_ids, custom_action)

        add_recipients(user_scope.where(id: user_ids), :custom, nil)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def add_project_watchers
        add_recipients(project_watchers, :watch, nil) if project
      end

      def add_group_watchers
        add_recipients(group_watchers, :watch, nil)
      end

      # Get project users with WATCH notification level
      # rubocop: disable CodeReuse/ActiveRecord
      def project_watchers
        project_members_ids = user_ids_notifiable_on(project)

        user_ids_with_project_global = user_ids_notifiable_on(project, :global)
        user_ids_with_group_global   = user_ids_notifiable_on(project.group, :global)

        user_ids = user_ids_with_global_level_watch((user_ids_with_project_global + user_ids_with_group_global).uniq)

        user_ids_with_project_setting = select_project_members_ids(user_ids_with_project_global, user_ids)
        user_ids_with_group_setting = select_group_members_ids(project.group, project_members_ids, user_ids_with_group_global, user_ids)

        user_scope.where(id: user_ids_with_project_setting.concat(user_ids_with_group_setting).uniq)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def group_watchers
        user_ids_with_group_global = user_ids_notifiable_on(group, :global)
        user_ids = user_ids_with_global_level_watch(user_ids_with_group_global)
        user_ids_with_group_setting = select_group_members_ids(group, [], user_ids_with_group_global, user_ids)

        user_scope.where(id: user_ids_with_group_setting)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def add_subscribed_users
        return unless target.respond_to? :subscribers

        add_recipients(target.subscribers(project), :subscription, NotificationReason::SUBSCRIBED)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def user_ids_notifiable_on(resource, notification_level = nil)
        return [] unless resource

        scope = resource.notification_settings

        if notification_level
          scope = scope.where(level: NotificationSetting.levels[notification_level])
        end

        scope.pluck(:user_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Build a list of user_ids based on project notification settings
      def select_project_members_ids(global_setting, user_ids_global_level_watch)
        user_ids = user_ids_notifiable_on(project, :watch)

        # If project setting is global, add to watch list if global setting is watch
        user_ids + (global_setting & user_ids_global_level_watch)
      end

      # Build a list of user_ids based on group notification settings
      def select_group_members_ids(group, project_members, global_setting, user_ids_global_level_watch)
        uids = user_ids_notifiable_on(group, :watch)

        # Group setting is global, add to user_ids list if global setting is watch
        uids + (global_setting & user_ids_global_level_watch) - project_members
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def user_ids_with_global_level_watch(ids)
        settings_with_global_level_of(:watch, ids).pluck(:user_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def user_ids_with_global_level_custom(ids, action)
        settings_with_global_level_of(:custom, ids).pluck(:user_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def settings_with_global_level_of(level, ids)
        NotificationSetting.where(
          user_id: ids,
          source_type: nil,
          level: NotificationSetting.levels[level]
        )
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def add_labels_subscribers(labels: nil)
        return unless target.respond_to? :labels

        (labels || target.labels).each do |label|
          add_recipients(label.subscribers(project), :subscription, NotificationReason::SUBSCRIBED)
        end
      end
    end
  end
end
