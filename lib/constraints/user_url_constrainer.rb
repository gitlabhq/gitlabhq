# frozen_string_literal: true

module Constraints
  class UserUrlConstrainer
    def matches?(request)
      full_path = request.params[:username]

      return false unless NamespacePathValidator.valid_path?(full_path)

      User.find_by_full_path(full_path, follow_redirects: request.get?).present?
    end
  end
end
