# frozen_string_literal: true

# This module is used to return fake strong password for tests

module Gitlab
  module Password
    DEFAULT_LENGTH = 12
    TEST_DEFAULT = "123qweQWE!@#" + "0" * (User.password_length.max - DEFAULT_LENGTH)
    def self.test_default(length = 12)
      password_length = [[User.password_length.min, length].max, User.password_length.max].min
      TEST_DEFAULT[...password_length]
    end
  end
end
