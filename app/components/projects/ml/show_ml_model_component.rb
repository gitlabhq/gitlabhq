# frozen_string_literal: true

module Projects
  module Ml
    class ShowMlModelComponent < ViewComponent::Base
      attr_reader :model, :current_user

      def initialize(model:, current_user:)
        @model = model.present
        @current_user = current_user
      end

      private

      def view_model
        vm = {
          model: {
            id: model.id,
            name: model.name,
            path: model.path,
            description: model.description,
            latest_version: latest_version_view_model,
            version_count: model.version_count,
            candidate_count: model.candidate_count
          }
        }

        Gitlab::Json.generate(vm.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      def latest_version_view_model
        return unless model.latest_version

        model_version = model.latest_version.present

        {
          version: model_version.version,
          description: model_version.description,
          path: model_version.path,
          project_path: project_path(model_version.project),
          package_id: model_version.package_id,
          **::Ml::CandidateDetailsPresenter.new(model_version.candidate, current_user).present
        }
      end
    end
  end
end
