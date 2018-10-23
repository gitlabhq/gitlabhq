# frozen_string_literal: true

# A simple finding for obtaining a single User.
#
# While using `User.find_by` directly is straightforward, it can lead to a lot
# of code duplication. Sometimes we just want to find a user by an ID, other
# times we may want to exclude blocked user. By using this finder (and extending
# it whenever necessary) we can keep this logic in one place.
class UserFinder
  def initialize(username_or_id)
    @username_or_id = username_or_id
  end

  # Tries to find a User by id, returning nil if none could be found.
  def find_by_id
    User.find_by_id(@username_or_id)
  end

  # Tries to find a User by id, raising a `ActiveRecord::RecordNotFound` if it could
  # not be found.
  def find_by_id!
    User.find(@username_or_id)
  end

  # Tries to find a User by username, returning nil if none could be found.
  def find_by_username
    User.find_by_username(@username_or_id)
  end

  # Tries to find a User by username, raising a `ActiveRecord::RecordNotFound` if it could
  # not be found.
  def find_by_username!
    User.find_by_username!(@username_or_id)
  end

  # Tries to find a User by username or id, returning nil if none could be found.
  def find_by_id_or_username
    if input_is_id?
      find_by_id
    else
      find_by_username
    end
  end

  # Tries to find a User by username or id, raising a `ActiveRecord::RecordNotFound` if it could
  # not be found.
  def find_by_id_or_username!
    if input_is_id?
      find_by_id!
    else
      find_by_username!
    end
  end

  def input_is_id?
    @username_or_id.is_a?(Numeric) || @username_or_id =~ /^\d+$/
  end
end
