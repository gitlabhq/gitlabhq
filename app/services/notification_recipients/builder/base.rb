# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class Base
      include ::Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 100

      def initialize(*)
        raise 'abstract'
      end

      def build!
        raise 'abstract'
      end

      def filter!
        preload_notification_settings
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
      strong_memoize_attr :project

      def group
        project&.group || target.try(:group)
      end
      strong_memoize_attr :group

      def recipients
        @recipients ||= []
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def add_recipients(users, type, reason)
        if users.is_a?(ActiveRecord::Relation)
          users = users.includes(:notification_settings)
            .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/421821')
        end

        users = Array(users).compact
        preload_users_namespace_bans(users)

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
        notification_by_sources = related_notification_settings_sources(:custom)

        return if notification_by_sources.blank?

        user_ids = NotificationSetting.from_union(notification_by_sources).select(:user_id)

        add_recipients(user_scope.where(id: user_ids), :custom, nil)
      end

      def related_notification_settings_sources(level)
        sources = [project, group].compact

        sources.map do |source|
          source
            .notification_settings
            .where(source_or_global_setting_by_level_query(level)).select(:user_id)
        end
      end

      def global_setting_by_level_query(level)
        table = NotificationSetting.arel_table
        aliased_table = table.alias

        table
          .project('true')
          .from(aliased_table)
          .where(
            aliased_table[:user_id].eq(table[:user_id])
              .and(aliased_table[:source_id].eq(nil))
              .and(aliased_table[:source_type].eq(nil))
              .and(aliased_table[:level].eq(level))
          ).exists
      end

      def source_or_global_setting_by_level_query(level)
        table = NotificationSetting.arel_table
        table.grouping(
          table[:level].eq(:global).and(global_setting_by_level_query(level))
        ).or(table[:level].eq(level))
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
        notification_by_sources = related_notification_settings_sources(:watch)

        return if notification_by_sources.blank?

        user_ids = NotificationSetting.from_union(notification_by_sources).select(:user_id)

        user_scope.where(id: user_ids)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def group_watchers
        return [] unless group

        user_ids = group
          .notification_settings
          .where(source_or_global_setting_by_level_query(:watch)).select(:user_id)

        user_scope.where(id: user_ids)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def add_subscribed_users
        return unless target.respond_to? :subscribers

        add_recipients(target.subscribers(project), :subscription, NotificationReason::SUBSCRIBED)
      end

      def add_labels_subscribers(labels: nil)
        return unless target.respond_to? :labels

        (labels || target.labels).each do |label|
          add_recipients(label.subscribers(project), :subscription, NotificationReason::SUBSCRIBED)
        end
      end

      private

      def preload_notification_settings
        sources = [project, group&.self_and_ancestors_asc, nil].flatten

        ActiveRecord::Associations::Preloader.new(
          records: recipients.map(&:user), associations: [:notification_settings],
          scope: NotificationSetting.by_sources(sources)
        ).call
      end

      def preload_users_namespace_bans(_users)
        # overridden in EE
      end
    end
  end
end

NotificationRecipients::Builder::Base.prepend_mod_with('NotificationRecipients::Builder::Base')
