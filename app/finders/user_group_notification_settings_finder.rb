# frozen_string_literal: true

class UserGroupNotificationSettingsFinder
  def initialize(user, groups)
    @user = user
    @groups = groups
  end

  def execute
    groups_with_ancestors = groups.self_and_ancestors
    @loaded_groups_with_ancestors = groups_with_ancestors.index_by(&:id)
    @loaded_notification_settings = user.notification_settings_for_groups(groups_with_ancestors)
                                        .preload_source_route.index_by(&:source_id)

    preload_emails_enabled

    group_notifications = groups.map do |group|
      find_notification_setting_for(group)
    end

    group_sources = group_notifications.map(&:source)
    ActiveRecord::Associations::Preloader.new(records: group_sources, associations: :namespace_settings).call

    group_notifications
  end

  private

  attr_reader :user, :groups, :loaded_groups_with_ancestors, :loaded_notification_settings

  def find_notification_setting_for(group)
    return loaded_notification_settings[group.id] if loaded_notification_settings[group.id]
    return user.notification_settings.build(source: group) if group.parent_id.nil?

    parent_setting = loaded_notification_settings[group.parent_id]

    return user.notification_settings.build(source: group) unless parent_setting

    if should_copy?(parent_setting)
      user.notification_settings.build(source: group) do |ns|
        ns.assign_attributes(parent_setting.slice(*NotificationSetting.allowed_fields))
      end
    else
      find_notification_setting_for(loaded_groups_with_ancestors[group.parent_id])
    end
  end

  def should_copy?(parent_setting)
    return false unless parent_setting

    parent_setting.level != NotificationSetting.levels[:global] || parent_setting.notification_email.present?
  end

  # This method preloads the `emails_enabled` strong memoized method for the given groups.
  #
  # For each group, look up the ancestor hierarchy and look for any group where emails_enabled is false.
  # The lookup is implemented with an EXISTS subquery, so we can look up the ancestor chain for each group individually.
  # The query will return groups where at least one ancestor has the `emails_disabled` set to true.
  #
  # After the query, we set the instance variable.
  def preload_emails_enabled
    group_ids_with_disabled_email = Group.ids_with_disabled_email(groups.to_a)

    groups.each do |group|
      group.emails_enabled_memoized = group_ids_with_disabled_email.exclude?(group.id) if group.parent_id
    end
  end
end
