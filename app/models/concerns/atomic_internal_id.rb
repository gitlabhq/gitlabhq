# frozen_string_literal: true

# Include atomic internal id generation scheme for a model
#
# This allows us to atomically generate internal ids that are
# unique within a given scope.
#
# For example, let's generate internal ids for Issue per Project:
# ```
# class Issue < ApplicationRecord
#   has_internal_id :iid, scope: :project, init: ->(s) { s.project.issues.maximum(:iid) }
# end
# ```
#
# This generates unique internal ids per project for newly created issues.
# The generated internal id is saved in the `iid` attribute of `Issue`.
#
# This concern uses InternalId records to facilitate atomicity.
# In the absence of a record for the given scope, one will be created automatically.
# In this situation, the `init` block is called to calculate the initial value.
# In the example above, we calculate the maximum `iid` of all issues
# within the given project.
#
# Note that a model may have more than one internal id associated with possibly
# different scopes.
module AtomicInternalId
  extend ActiveSupport::Concern

  class_methods do
    def has_internal_id(column, scope:, init:, ensure_if: nil, track_if: nil, presence: true) # rubocop:disable Naming/PredicateName
      # We require init here to retain the ability to recalculate in the absence of a
      # InternalId record (we may delete records in `internal_ids` for example).
      raise "has_internal_id requires a init block, none given." unless init
      raise "has_internal_id needs to be defined on association." unless self.reflect_on_association(scope)

      before_validation :"track_#{scope}_#{column}!", on: :create, if: track_if
      before_validation :"ensure_#{scope}_#{column}!", on: :create, if: ensure_if
      validates column, presence: presence

      define_method("ensure_#{scope}_#{column}!") do
        scope_value = internal_id_read_scope(scope)
        value = read_attribute(column)
        return value unless scope_value

        if value.nil?
          # We don't have a value yet and use a InternalId record to generate
          # the next value.
          value = InternalId.generate_next(
            self,
            internal_id_scope_attrs(scope),
            internal_id_scope_usage,
            init)
          write_attribute(column, value)
        end

        value
      end

      define_method("track_#{scope}_#{column}!") do
        return unless @internal_id_needs_tracking

        scope_value = internal_id_read_scope(scope)
        return unless scope_value

        value = read_attribute(column)

        if value.present?
          # The value was set externally, e.g. by the user
          # We update the InternalId record to keep track of the greatest value.
          InternalId.track_greatest(
            self,
            internal_id_scope_attrs(scope),
            internal_id_scope_usage,
            value,
            init)

          @internal_id_needs_tracking = false
        end
      end

      define_method("#{column}=") do |value|
        super(value).tap do |v|
          # Indicate the iid was set from externally
          @internal_id_needs_tracking = true
        end
      end

      define_method("reset_#{scope}_#{column}") do
        if value = read_attribute(column)
          did_reset = InternalId.reset(
            self,
            internal_id_scope_attrs(scope),
            internal_id_scope_usage,
            value)

          if did_reset
            write_attribute(column, nil)
          end
        end

        read_attribute(column)
      end
    end
  end

  def internal_id_scope_attrs(scope)
    scope_value = internal_id_read_scope(scope)

    { scope_value.class.table_name.singularize.to_sym => scope_value } if scope_value
  end

  def internal_id_scope_usage
    self.class.table_name.to_sym
  end

  def internal_id_read_scope(scope)
    association(scope).reader
  end
end
