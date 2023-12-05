# frozen_string_literal: true

module Projects
  module Ml
    class ShowMlModelVersionComponent < ViewComponent::Base
      attr_reader :model_version, :model, :current_user

      def initialize(model_version:, current_user:)
        @model_version = model_version.present
        @model = model_version.model.present
        @current_user = current_user
      end

      private

      def view_model
        vm = {
          model_version: {
            id: model_version.id,
            version: model_version.version,
            path: model_version.path,
            description: model_version.description,
            project_path: project_path(model_version.project),
            package_id: model_version.package_id,
            model: {
              name: model.name,
              path: model.path
            },
            **candidate_data
          }
        }

        Gitlab::Json.generate(vm.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      def candidate_data
        ::Ml::CandidateDetailsPresenter.new(model_version.candidate, current_user).present
      end
    end
  end
end
