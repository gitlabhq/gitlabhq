# frozen_string_literal: true

module Projects
  module Ml
    class ModelsIndexComponent < ViewComponent::Base
      attr_reader :paginator

      def initialize(paginator:)
        @paginator = paginator
      end

      private

      def view_model
        vm = {
          models: models_view_model,
          page_info: page_info_view_model
        }

        Gitlab::Json.generate(vm.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      def models_view_model
        paginator.records.map(&:present).map do |m|
          {
            name: m.name,
            version: m.latest_version_name,
            version_count: m.version_count,
            path: m.latest_package_path
          }
        end
      end

      def page_info_view_model
        {
          has_next_page: paginator.has_next_page?,
          has_previous_page: paginator.has_previous_page?,
          start_cursor: paginator.cursor_for_previous_page,
          end_cursor: paginator.cursor_for_next_page
        }
      end
    end
  end
end
