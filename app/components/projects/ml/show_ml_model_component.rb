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
            path: model.path
          }
        }

        Gitlab::Json.generate(vm)
      end
    end
  end
end
