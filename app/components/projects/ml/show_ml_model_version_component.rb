# frozen_string_literal: true

module Projects
  module Ml
    class ShowMlModelVersionComponent < ViewComponent::Base
      attr_reader :model_version, :model

      def initialize(model_version:)
        @model_version = model_version.present
        @model = model_version.model.present
      end

      private

      def view_model
        vm = {
          model_version: {
            id: model_version.id,
            version: model_version.version,
            path: model_version.path,
            model: {
              name: model.name,
              path: model.path
            }
          }
        }

        Gitlab::Json.generate(vm.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end
    end
  end
end
