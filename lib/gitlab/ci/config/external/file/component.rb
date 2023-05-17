# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Component < Base
            extend ::Gitlab::Utils::Override
            include Gitlab::Utils::StrongMemoize

            def initialize(params, context)
              @location = params[:component]

              super
            end

            def matching?
              super && ::Feature.enabled?(:ci_include_components, context.project&.root_namespace)
            end

            def content
              return unless component_result.success?

              component_result.payload.fetch(:content)
            end
            strong_memoize_attr :content

            def metadata
              super.merge(
                type: :component,
                location: masked_location,
                blob: masked_blob,
                raw: nil,
                extra: {}
              )
            end

            def validate_location!
              return unless invalid_location_type?

              errors.push("Included file `#{masked_location}` needs to be a string")
            end

            def validate_context!
              return if context.project&.repository

              errors.push('Unable to use components outside of a project context')
            end

            def validate_content!
              errors.push(component_result.message) unless content.present?
            end

            private

            attr_reader :path, :version

            def component_result
              ::Ci::Components::FetchService.new(
                address: location,
                current_user: context.user
              ).execute
            end
            strong_memoize_attr :component_result

            override :expand_context_attrs
            def expand_context_attrs
              {
                project: component_path.project,
                sha: component_path.sha,
                user: context.user,
                variables: context.variables
              }
            end

            def masked_blob
              return unless component_path

              context.mask_variables_from(
                Gitlab::Routing.url_helpers.project_blob_url(
                  component_path.project,
                  ::File.join(component_path.sha, component_path.project_file_path))
              )
            end
            strong_memoize_attr :masked_blob

            def component_path
              return unless component_result.success?

              component_result.payload.fetch(:path)
            end
            strong_memoize_attr :component_path
          end
        end
      end
    end
  end
end
