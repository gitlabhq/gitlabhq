# frozen_string_literal: true

module Releases
  module Links
    class UpdateService < BaseService
      def execute(link)
        return ServiceResponse.error(message: _('Access Denied')) unless allowed?
        return ServiceResponse.error(message: _('Link does not exist')) unless link

        if link.update(allowed_params)
          ServiceResponse.success(payload: { link: link })
        else
          ServiceResponse.error(message: link.errors.full_messages)
        end
      end

      private

      def allowed?
        Ability.allowed?(current_user, :update_release, release)
      end
    end
  end
end
