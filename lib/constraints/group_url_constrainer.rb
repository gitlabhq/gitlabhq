# frozen_string_literal: true

module Constraints
  class GroupUrlConstrainer
    def matches?(request)
      full_path = request.params[:group_id] || request.params[:id]

      return false unless NamespacePathValidator.valid_path?(full_path)

      Group.find_by_full_path(full_path, follow_redirects: request.get?).present?
    end
  end
end
