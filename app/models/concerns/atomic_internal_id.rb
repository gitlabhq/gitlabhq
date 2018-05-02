# Include atomic internal id generation scheme for a model
#
# This allows us to atomically generate internal ids that are
# unique within a given scope.
#
# For example, let's generate internal ids for Issue per Project:
# ```
# class Issue < ActiveRecord::Base
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

  module ClassMethods
    def has_internal_id(column, scope:, init:) # rubocop:disable Naming/PredicateName
      before_validation(on: :create) do
        scope_value = association(scope).reader
        if read_attribute(column).blank? && scope_value
          scope_attrs = { scope_value.class.table_name.singularize.to_sym => scope_value }
          usage = self.class.table_name.to_sym

          new_iid = InternalId.generate_next(self, scope_attrs, usage, init)
          write_attribute(column, new_iid)
        end
      end

      validates column, presence: true, numericality: true
    end
  end

  def to_param
    iid.to_s
  end
end
