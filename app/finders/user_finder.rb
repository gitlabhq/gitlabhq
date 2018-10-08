# frozen_string_literal: true

# A simple finding for obtaining a single User.
#
# While using `User.find_by` directly is straightforward, it can lead to a lot
# of code duplication. Sometimes we just want to find a user by an ID, other
# times we may want to exclude blocked user. By using this finder (and extending
# it whenever necessary) we can keep this logic in one place.
class UserFinder
  attr_reader :params

  def initialize(params)
    @params = params
  end

  # Tries to find a User, returning nil if none could be found.
  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    User.find_by(id: params[:id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # Tries to find a User, raising a `ActiveRecord::RecordNotFound` if it could
  # not be found.
  def execute!
    User.find(params[:id])
  end
end
