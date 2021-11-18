# frozen_string_literal: true

# A module that makes it easier/less verbose to reflect upon a database
# connection.
#
# Using this module you can write this:
#
#     User.database.database_name
#
# Instead of this:
#
#     Gitlab::Database::Reflection.new(User).database_name
module DatabaseReflection
  extend ActiveSupport::Concern

  class_methods do
    def database
      @database_reflection ||= ::Gitlab::Database::Reflection.new(self)
    end
  end
end
