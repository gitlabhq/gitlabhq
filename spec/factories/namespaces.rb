# A Namespace is either a Group, or is owned by a User. There is no such thing
# as a Namespace that not a Group and is not owned by a User. Note that there
# may be legacy data in which a Group has an `owner_id`, but `type == 'Group'`
# takes priority.`
#
# Due to the either-or relationship above, it usually makes more sense to create
# a User and get their Namespace, or create a Group directly, since it is itself
# a Namespace.
#
# This factory assumes you want a Namespace owned by a User.
#
# Do not try to use this factory to create a Namespace and set `name` or `path`
# since that is automatically determined by the User's `username`. The resultant
# Namespace would fail validation that checks for matching `username`, `name`
# and `path`.
FactoryGirl.define do
  factory :namespace do
    owner

    initialize_with do
      # A namespace is automatically created when a user is created
      owner&.namespace || new
    end
  end
end
