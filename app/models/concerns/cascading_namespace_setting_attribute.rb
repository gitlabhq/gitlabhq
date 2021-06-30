# frozen_string_literal: true

#
# Cascading attributes enables managing settings in a flexible way.
#
# - Instance administrator can define an instance-wide default setting, or
#   lock the setting to prevent change by group owners.
# - Group maintainers/owners can define a default setting for their group, or
#   lock the setting to prevent change by sub-group maintainers/owners.
#
# Behavior:
#
# - When a group does not have a value (value is `nil`), cascade up the
#   hierarchy to find the first non-nil value.
# - Settings can be locked at any level to prevent groups/sub-groups from
#   overriding.
# - If the setting isn't locked, the default can be overridden.
# - An instance administrator or group maintainer/owner can push settings values
#   to groups/sub-groups to override existing values, even when the setting
#   is not otherwise locked.
#
module CascadingNamespaceSettingAttribute
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  class_methods do
    private

    # Facilitates the cascading lookup of values and,
    # similar to Rails' `attr_accessor`, defines convenience methods such as
    # a reader, writer, and validators.
    #
    # Example: `cascading_attr :delayed_project_removal`
    #
    # Public methods defined:
    # - `delayed_project_removal`
    # - `delayed_project_removal=`
    # - `delayed_project_removal_locked?`
    # - `delayed_project_removal_locked_by_ancestor?`
    # - `delayed_project_removal_locked_by_application_setting?`
    # - `delayed_project_removal?` (only defined for boolean attributes)
    # - `delayed_project_removal_locked_ancestor` - Returns locked namespace settings object (only namespace_id)
    #
    # Defined validators ensure attribute value cannot be updated if locked by
    # an ancestor or application settings.
    #
    # Requires database columns be present in both `namespace_settings` and
    # `application_settings`.
    def cascading_attr(*attributes)
      attributes.map(&:to_sym).each do |attribute|
        # public methods
        define_attr_reader(attribute)
        define_attr_writer(attribute)
        define_lock_attr_writer(attribute)
        define_lock_methods(attribute)
        alias_boolean(attribute)

        # private methods
        define_validator_methods(attribute)
        define_after_update(attribute)

        validate :"#{attribute}_changeable?"
        validate :"lock_#{attribute}_changeable?"

        after_update :"clear_descendant_#{attribute}_locks", if: -> { saved_change_to_attribute?("lock_#{attribute}", to: true) }
      end
    end

    # The cascading attribute reader method handles lookups
    # with the following criteria:
    #
    # 1. Returns the dirty value, if the attribute has changed.
    # 2. Return locked ancestor value.
    # 3. Return locked instance-level application settings value.
    # 4. Return this namespace's attribute, if not nil.
    # 5. Return value from nearest ancestor where value is not nil.
    # 6. Return instance-level application setting.
    def define_attr_reader(attribute)
      define_method(attribute) do
        strong_memoize(attribute) do
          next self[attribute] if will_save_change_to_attribute?(attribute)
          next locked_value(attribute) if cascading_attribute_locked?(attribute, include_self: false)
          next self[attribute] unless self[attribute].nil?

          cascaded_value = cascaded_ancestor_value(attribute)
          next cascaded_value unless cascaded_value.nil?

          application_setting_value(attribute)
        end
      end
    end

    def define_attr_writer(attribute)
      define_method("#{attribute}=") do |value|
        return value if value == cascaded_ancestor_value(attribute)

        clear_memoization(attribute)
        super(value)
      end
    end

    def define_lock_attr_writer(attribute)
      define_method("lock_#{attribute}=") do |value|
        attr_value = public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
        write_attribute(attribute, attr_value) if self[attribute].nil?

        super(value)
      end
    end

    def define_lock_methods(attribute)
      define_method("#{attribute}_locked?") do |include_self: false|
        cascading_attribute_locked?(attribute, include_self: include_self)
      end

      define_method("#{attribute}_locked_by_ancestor?") do
        locked_by_ancestor?(attribute)
      end

      define_method("#{attribute}_locked_by_application_setting?") do
        locked_by_application_setting?(attribute)
      end

      define_method("#{attribute}_locked_ancestor") do
        locked_ancestor(attribute)
      end
    end

    def alias_boolean(attribute)
      return unless Gitlab::Database.exists? && type_for_attribute(attribute).type == :boolean

      alias_method :"#{attribute}?", attribute
    end

    # Defines two validations - one for the cascadable attribute itself and one
    # for the lock attribute. Only allows the respective value to change if
    # an ancestor has not already locked the value.
    def define_validator_methods(attribute)
      define_method("#{attribute}_changeable?") do
        return unless cascading_attribute_changed?(attribute)
        return unless cascading_attribute_locked?(attribute, include_self: false)

        errors.add(attribute, s_('CascadingSettings|cannot be changed because it is locked by an ancestor'))
      end

      define_method("lock_#{attribute}_changeable?") do
        return unless cascading_attribute_changed?("lock_#{attribute}")

        if cascading_attribute_locked?(attribute, include_self: false)
          return errors.add(:"lock_#{attribute}", s_('CascadingSettings|cannot be changed because it is locked by an ancestor'))
        end

        # Don't allow locking a `nil` attribute.
        # Even if the value being locked is currently cascaded from an ancestor,
        # it should be copied to this record to avoid the ancestor changing the
        # value unexpectedly later.
        return unless self[attribute].nil? && public_send("lock_#{attribute}?") # rubocop:disable GitlabSecurity/PublicSend

        errors.add(attribute, s_('CascadingSettings|cannot be nil when locking the attribute'))
      end

      private :"#{attribute}_changeable?", :"lock_#{attribute}_changeable?"
    end

    # When a particular group locks the attribute, clear all sub-group locks
    # since the higher lock takes priority.
    def define_after_update(attribute)
      define_method("clear_descendant_#{attribute}_locks") do
        self.class.where(namespace_id: descendants).update_all("lock_#{attribute}" => false)
      end

      private :"clear_descendant_#{attribute}_locks"
    end
  end

  private

  def locked_value(attribute)
    ancestor = locked_ancestor(attribute)
    return ancestor.read_attribute(attribute) if ancestor

    Gitlab::CurrentSettings.public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
  end

  def locked_ancestor(attribute)
    return unless namespace.has_parent?

    strong_memoize(:"#{attribute}_locked_ancestor") do
      self.class
        .select(:namespace_id, "lock_#{attribute}", attribute)
        .where(namespace_id: namespace_ancestor_ids)
        .where(self.class.arel_table["lock_#{attribute}"].eq(true))
        .limit(1).load.first
    end
  end

  def locked_by_ancestor?(attribute)
    locked_ancestor(attribute).present?
  end

  def locked_by_application_setting?(attribute)
    Gitlab::CurrentSettings.public_send("lock_#{attribute}") # rubocop:disable GitlabSecurity/PublicSend
  end

  def cascading_attribute_locked?(attribute, include_self:)
    locked_by_self = include_self ? public_send("lock_#{attribute}?") : false # rubocop:disable GitlabSecurity/PublicSend
    locked_by_self || locked_by_ancestor?(attribute) || locked_by_application_setting?(attribute)
  end

  def cascading_attribute_changed?(attribute)
    public_send("#{attribute}_changed?") # rubocop:disable GitlabSecurity/PublicSend
  end

  def cascaded_ancestor_value(attribute)
    return unless namespace.has_parent?

    # rubocop:disable GitlabSecurity/SqlInjection
    self.class
      .select(attribute)
      .joins("join unnest(ARRAY[#{namespace_ancestor_ids.join(',')}]) with ordinality t(namespace_id, ord) USING (namespace_id)")
      .where("#{attribute} IS NOT NULL")
      .order('t.ord')
      .limit(1).first&.read_attribute(attribute)
    # rubocop:enable GitlabSecurity/SqlInjection
  end

  def application_setting_value(attribute)
    Gitlab::CurrentSettings.public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
  end

  def namespace_ancestor_ids
    strong_memoize(:namespace_ancestor_ids) do
      namespace.ancestor_ids(hierarchy_order: :asc)
    end
  end

  def descendants
    strong_memoize(:descendants) do
      namespace.descendants.pluck(:id)
    end
  end
end
