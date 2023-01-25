# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Template < Base
            attr_reader :location

            SUFFIX = '.gitlab-ci.yml'
            HOST = 'https://gitlab.com/gitlab-org/gitlab/-/raw/master'

            def initialize(params, context)
              @location = params[:template]

              super
            end

            def content
              strong_memoize(:content) { fetch_template_content }
            end

            def metadata
              super.merge(
                type: :template,
                location: masked_location,
                blob: nil,
                raw: masked_raw,
                extra: {}
              )
            end

            def validate_context!
              # no-op
            end

            def validate_location!
              super

              unless template_name_valid?
                errors.push("Template file `#{masked_location}` is not a valid location!")
              end
            end

            private

            def template_name
              return unless template_name_valid?

              location.delete_suffix(SUFFIX)
            end

            def template_name_valid?
              location.to_s.end_with?(SUFFIX)
            end

            def fetch_template_content
              context.logger.instrument(:config_file_fetch_template_content) do
                Gitlab::Template::GitlabCiYmlTemplate.find(template_name, context.project)&.content
              end
            end

            def masked_raw
              strong_memoize(:masked_raw) do
                context.mask_variables_from(
                  "#{HOST}/#{Gitlab::Template::GitlabCiYmlTemplate::BASE_DIR}/#{location}"
                )
              end
            end
          end
        end
      end
    end
  end
end
