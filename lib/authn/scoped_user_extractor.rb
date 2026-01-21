# frozen_string_literal: true

module Authn
  module ScopedUserExtractor
    SCOPED_USER_REGEX = /\Auser:(\d+)\z/

    module_function

    def extract_user_id_from_scopes(scopes)
      matches = scopes.grep(SCOPED_USER_REGEX)
      return unless matches.length == 1

      matches[0][SCOPED_USER_REGEX, 1].to_i
    end
  end
end
