# frozen_string_literal: true

module Releases
  module Links
    class CreateService < BaseService
      def execute
        return ServiceResponse.error(message: _('Access Denied')) unless allowed?

        link = release.links.create(allowed_params)

        if link.persisted?
          ServiceResponse.success(payload: { link: link })
        else
          ServiceResponse.error(message: link.errors.full_messages)
        end
      end

      private

      def allowed?
        Ability.allowed?(current_user, :create_release, release)
      end
    end
  end
end
