# Module to prepend into finders to specify wether or not the finder requires
# cross project access
#
# This module depends on the finder implementing the following methods:
#
# - `#execute` should return an `ActiveRecord::Relation`
# - `#current_user` the user that requires access (or nil)
module FinderWithCrossProjectAccess
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  prepended do
    extend Gitlab::CrossProjectAccess::ClassMethods
  end

  override :execute
  def execute(*args)
    check = Gitlab::CrossProjectAccess.find_check(self)
    original = super

    return original unless check
    return original if should_skip_cross_project_check || can_read_cross_project?

    if check.should_run?(self)
      original.model.none
    else
      original
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

  private

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
