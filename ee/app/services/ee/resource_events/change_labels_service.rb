# frozen_string_literal: true

module EE
  module ResourceEvents
    module ChangeLabelsService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :resource_column
      def resource_column(resource)
        resource.is_a?(Epic) ? :epic_id : super
      end
    end
  end
end
