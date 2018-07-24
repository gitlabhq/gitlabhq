# frozen_string_literal: true

module Projects
  module GroupLinks
    class DestroyService < BaseService
      prepend ::EE::Projects::GroupLinks::DestroyService

      def execute(group_link)
        return false unless group_link

        group_link.destroy
      end
    end
  end
end
