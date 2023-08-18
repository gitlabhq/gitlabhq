# frozen_string_literal: true

module Projects
  module Ml
    class ModelsIndexComponent < ViewComponent::Base
      attr_reader :models

      def initialize(models:)
        @models = models
      end

      private

      def view_model
        Gitlab::Json.generate({ models: models_view_model })
      end

      def models_view_model
        models.map(&:present).map do |m|
          {
            name: m.name,
            version: m.latest_version_name,
            path: m.latest_package_path
          }
        end
      end
    end
  end
end
