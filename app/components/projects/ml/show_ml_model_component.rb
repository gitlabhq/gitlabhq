# frozen_string_literal: true

module Projects
  module Ml
    class ShowMlModelComponent < ViewComponent::Base
      attr_reader :model

      def initialize(model:)
        @model = model.present
      end

      private

      def view_model
        vm = {
          model: {
            id: model.id,
            name: model.name,
            path: model.path,
            description: "This is a placeholder for the short description",
            latest_version: latest_version_view_model,
            version_count: model.version_count
          }
        }

        Gitlab::Json.generate(vm.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      def latest_version_view_model
        return unless model.latest_version

        {
          version: model.latest_version.version
        }
      end
    end
  end
end
