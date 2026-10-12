# frozen_string_literal: true

module WorkItems
  module Widgets
    class Requester < Base
      # Email address of the non-GitLab user who requested the ticket through Service Desk
      def email
        work_item.external_author
      end
    end
  end
end
