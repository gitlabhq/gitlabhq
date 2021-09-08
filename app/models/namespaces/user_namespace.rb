# frozen_string_literal: true

# TODO: currently not created/mapped in the database, will be done in another issue
#       https://gitlab.com/gitlab-org/gitlab/-/issues/337102
module Namespaces
  class UserNamespace < Namespace
    def self.sti_name
      'User'
    end
  end
end
