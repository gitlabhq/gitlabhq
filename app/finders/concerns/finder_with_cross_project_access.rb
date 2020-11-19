# frozen_string_literal: true

# Module to prepend into finders to specify whether or not the finder requires
# cross project access
#
# This module depends on the finder implementing the following methods:
#
# - `#execute` should return an `ActiveRecord::Relation` or the `model` needs to
#              be defined in the call to `requires_cross_project_access`.
# - `#current_user` the user that requires access (or nil)
module FinderWithCrossProjectAccess
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  prepended do
    extend Gitlab::CrossProjectAccess::ClassMethods

    cattr_accessor :finder_model

    def self.requires_cross_project_access(*args)
      super

      self.finder_model = extract_model_from_arguments(args)
    end

    private

    def self.extract_model_from_arguments(args)
      args.detect { |argument| argument.is_a?(Hash) && argument[:model] }
        &.fetch(:model)
    end
  end

  override :execute
  def execute(*args, **kwargs)
    check = Gitlab::CrossProjectAccess.find_check(self)
    original = -> { super }

    return original.call unless check
    return original.call if should_skip_cross_project_check || can_read_cross_project?

    if check.should_run?(self)
      finder_model&.none || original.call.model.none
    else
      original.call
    end
  end

  # We can skip the cross project check for finding indivitual records.
  # this would be handled by the `can?(:read_*, result)` call in `FinderMethods`
  # itself.
  override :find_by!
  def find_by!(*args)
    skip_cross_project_check { super }
  end

  override :find_by
  def find_by(*args)
    skip_cross_project_check { super }
  end

  override :find
  def find(*args)
    skip_cross_project_check { super }
  end

  attr_accessor :should_skip_cross_project_check

  def skip_cross_project_check
    self.should_skip_cross_project_check = true

    yield
  ensure
    # The find could raise an `ActiveRecord::RecordNotFound`, after which we
    # still want to re-enable the check.
    self.should_skip_cross_project_check = false
  end

  def can_read_cross_project?
    Ability.allowed?(current_user, :read_cross_project)
  end

  def can_read_project?(project)
    Ability.allowed?(current_user, :read_project, project)
  end
end
