#
# Used by NotificationService to determine who should receive notification
#
class NotificationRecipientService
  attr_reader :project

  def self.notification_setting_for_user_project(user, project)
    project_setting = project && user.notification_settings_for(project)

    return project_setting unless project_setting.nil? || project_setting.global?

    group_setting = project&.group && user.notification_settings_for(project.group)

    return group_setting unless group_setting.nil? || group_setting.global?

    user.global_notification_setting
  end

  def initialize(project)
    @project = project
  end

  class Recipient
    def self.notifiable_users(users, *args)
      users.map { |u| new(u, *args) }.select(&:notifiable?).map(&:user)
    end

    attr_reader :user, :type
    def initialize(user, project, type,
                   custom_action: nil, target: nil, acting_user: nil, read_ability: nil)
      @project = project
      @custom_action = custom_action
      @acting_user = acting_user
      @read_ability = read_ability
      @target = target
      @user = user
      @type = type
    end

    def notification_setting
      @notification_setting ||=
        NotificationRecipientService.notification_setting_for_user_project(user, @project)
    end

    def raw_notification_level
      notification_setting&.level&.to_sym
    end

    def notification_level
      # custom is treated the same as watch if it's enabled - otherwise it's
      # as :disabled.
      @notification_level ||=
        case raw_notification_level
        when :custom
          if @custom_action && notification_setting.event_enabled?(@custom_action)
            :watch
          else
            :custom
          end
        else
          raw_notification_level
        end
    end

    def notifiable?
      return false unless has_access?
      return false if own_activity?

      return true if @type == :subscription

      return false if notification_level.nil? || notification_level == :disabled

      return %i[participating mention].include?(@type) if notification_level == :custom

      return false if %i[watch participating].include?(notification_level) && excluded_watcher_action?

      return false unless NotificationSetting.levels[notification_level] <= NotificationSetting.levels[type]

      return false if unsubscribed?

      true
    end

    def unsubscribed?
      return false unless @target
      return false unless @target.respond_to?(:subscriptions)

      subscription = @target.subscriptions.find_by_user_id(@user.id)
      subscription && !subscription.subscribed
    end

    def own_activity?
      return false unless @acting_user
      return false if @acting_user.notified_of_own_activity?

      user == @acting_user
    end

    def has_access?
      return false unless user.can?(:receive_notifications)
      return true unless @read_ability

      DeclarativePolicy.subject_scope do
        user.can?(@read_ability, @target)
      end
    end

    def excluded_watcher_action?
      return false unless @custom_action
      return false if raw_notification_level == :custom

      NotificationSetting::EXCLUDED_WATCHER_EVENTS.include?(@custom_action)
    end
  end

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

      def recipients
        @recipients ||= []
      end

      def <<(arg)
        users, type = arg
        users = Array(users)
        users.compact!
        recipients.concat(users.map { |u| make_recipient(u, type) })
      end

      def make_recipient(user, type)
        Recipient.new(user, project, type,
          custom_action: custom_action,
          target: target,
          acting_user: acting_user,
          read_ability: read_ability
        )
      end

      def recipient_users
        @recipient_users ||=
          begin
            build!
            filter!
            users = recipients.map(&:user)
            users.uniq!
            users.freeze
          end
      end

      def read_ability
        @read_ability ||=
          case target
          when Issuable
            :"read_#{target.to_ability_name}"
          when Ci::Pipeline
            :read_build # We have build trace in pipeline emails
          end
      end

      protected

      def add_participants(user)
        return unless target.respond_to?(:participants)

        self << [target.participants(user), :watch]
      end

      # Get project/group users with CUSTOM notification level
      def add_custom_notifications
        user_ids = []

        # Users with a notification setting on group or project
        user_ids += user_ids_notifiable_on(project, :custom)
        user_ids += user_ids_notifiable_on(project.group, :custom)

        # Users with global level custom
        user_ids_with_project_level_global = user_ids_notifiable_on(project, :global)
        user_ids_with_group_level_global   = user_ids_notifiable_on(project.group, :global)

        global_users_ids = user_ids_with_project_level_global.concat(user_ids_with_group_level_global)
        user_ids += user_ids_with_global_level_custom(global_users_ids, custom_action)

        self << [User.find(user_ids), :watch]
      end

      def add_project_watchers
        self << [project_watchers, :watch]
      end

      # Get project users with WATCH notification level
      def project_watchers
        project_members_ids = user_ids_notifiable_on(project)

        user_ids_with_project_global = user_ids_notifiable_on(project, :global)
        user_ids_with_group_global   = user_ids_notifiable_on(project.group, :global)

        user_ids = user_ids_with_global_level_watch((user_ids_with_project_global + user_ids_with_group_global).uniq)

        user_ids_with_project_setting = select_project_members_ids(project, user_ids_with_project_global, user_ids)
        user_ids_with_group_setting = select_group_members_ids(project.group, project_members_ids, user_ids_with_group_global, user_ids)

        User.where(id: user_ids_with_project_setting.concat(user_ids_with_group_setting).uniq).to_a
      end

      def add_subscribed_users
        return unless target.respond_to? :subscribers

        self << [target.subscribers(project), :subscription]
      end

      def user_ids_notifiable_on(resource, notification_level = nil)
        return [] unless resource

        scope = resource.notification_settings

        if notification_level
          scope = scope.where(level: NotificationSetting.levels[notification_level])
        end

        scope.pluck(:user_id)
      end

      # Build a list of user_ids based on project notification settings
      def select_project_members_ids(project, global_setting, user_ids_global_level_watch)
        user_ids = user_ids_notifiable_on(project, :watch)

        # If project setting is global, add to watch list if global setting is watch
        global_setting.each do |user_id|
          if user_ids_global_level_watch.include?(user_id)
            user_ids << user_id
          end
        end

        user_ids
      end

      # Build a list of user_ids based on group notification settings
      def select_group_members_ids(group, project_members, global_setting, user_ids_global_level_watch)
        uids = user_ids_notifiable_on(group, :watch)

        # Group setting is watch, add to user_ids list if user is not project member
        user_ids = []
        uids.each do |user_id|
          if project_members.exclude?(user_id)
            user_ids << user_id
          end
        end

        # Group setting is global, add to user_ids list if global setting is watch
        global_setting.each do |user_id|
          if project_members.exclude?(user_id) && user_ids_global_level_watch.include?(user_id)
            user_ids << user_id
          end
        end

        user_ids
      end

      def user_ids_with_global_level_watch(ids)
        settings_with_global_level_of(:watch, ids).pluck(:user_id)
      end

      def user_ids_with_global_level_custom(ids, action)
        settings = settings_with_global_level_of(:custom, ids)
        settings = settings.select { |setting| setting.event_enabled?(action) }
        settings.map(&:user_id)
      end

      def settings_with_global_level_of(level, ids)
        NotificationSetting.where(
          user_id: ids,
          source_type: nil,
          level: NotificationSetting.levels[level]
        )
      end

      def reject_unsubscribed_users
        return unless target.respond_to? :subscriptions

        recipients.reject! do |recipient|
          user = recipient.user
          subscription = target.subscriptions.find_by_user_id(user.id)
          subscription && !subscription.subscribed
        end
      end

      def reject_users_without_access
        recipients.select! { |r| r.user.can?(:receive_notifications) }

        return unless read_ability

        DeclarativePolicy.subject_scope do
          recipients.select! do |recipient|
            recipient.user.can?(read_ability, target)
          end
        end
      end

      def reject_user(user)
        recipients.reject! { |r| r.user == user }
      end

      def add_labels_subscribers(labels: nil)
        return unless target.respond_to? :labels

        (labels || target.labels).each do |label|
          self << [label.subscribers(project), :subscription]
        end
      end
    end

    class Default < Base
      attr_reader :project
      attr_reader :target
      attr_reader :current_user
      attr_reader :action
      attr_reader :previous_assignee
      attr_reader :skip_current_user
      def initialize(project, target, current_user, action:, previous_assignee: nil, skip_current_user: true)
        @project = project
        @target = target
        @current_user = current_user
        @action = action
        @previous_assignee = previous_assignee
        @skip_current_user = skip_current_user
      end

      def build!
        add_participants(current_user)
        add_project_watchers
        add_custom_notifications

        # Re-assign is considered as a mention of the new assignee
        case custom_action
        when :reassign_merge_request
          self << [previous_assignee, :mention]
          self << [target.assignee, :mention]
        when :reassign_issue
          previous_assignees = Array(previous_assignee)
          self << [previous_assignees, :mention]
          self << [target.assignees, :mention]
        end

        add_subscribed_users

        if [:new_issue, :new_merge_request].include?(custom_action)
          add_labels_subscribers
        end
      end

      def acting_user
        current_user if skip_current_user
      end

      # Build event key to search on custom notification level
      # Check NotificationSetting::EMAIL_EVENTS
      def custom_action
        @custom_action ||= "#{action}_#{target.class.model_name.name.underscore}".to_sym
      end
    end

    class Relabeled < Base
      attr_reader :project
      attr_reader :target
      attr_reader :current_user
      attr_reader :labels
      def initialize(project, target, current_user, labels:)
        @project = project
        @target = target
        @current_user = current_user
        @labels = labels
      end

      def build!
        add_labels_subscribers(labels: labels)
      end
    end

    class NewNote < Base
      attr_reader :project
      attr_reader :note
      attr_reader :target
      def initialize(project, note)
        @project = project
        @note = note
        @target = note.noteable
      end

      def read_ability
        @read_ability ||=
          case target
          when Commit then nil
          else :"read_#{target.class.model_name.name.underscore}"
          end
      end

      def subject
        note.for_personal_snippet? ? note.noteable : note.project
      end

      def build!
        # Add all users participating in the thread (author, assignee, comment authors)
        add_participants(note.author)
        self << [note.mentioned_users, :mention]

        unless note.for_personal_snippet?
          # Merge project watchers
          add_project_watchers

          # Merge project with custom notification
          add_custom_notifications
        end

        add_subscribed_users
      end

      def custom_action
        :new_note
      end

      def acting_user
        note.author
      end
    end
  end

  def self.notifiable_users(*a)
    Recipient.notifiable_users(*a)
  end

  def build_recipients(*a)
    Builder::Default.new(@project, *a).recipient_users
  end

  def build_relabeled_recipients(*a)
    Builder::Relabeled.new(@project, *a).recipient_users
  end

  def build_new_note_recipients(*a)
    Builder::NewNote.new(@project, *a).recipient_users
  end
end
