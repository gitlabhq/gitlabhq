# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Template < Base
            attr_reader :location, :project

            SUFFIX = '.gitlab-ci.yml'

            def initialize(params, context)
              @location = params[:template]

              super
            end

            def content
              strong_memoize(:content) { fetch_template_content }
            end

            private

            def validate_location!
              super

              unless template_name_valid?
                errors.push("Template file `#{location}` is not a valid location!")
              end
            end

            def template_name
              return unless template_name_valid?

              location.first(-SUFFIX.length)
            end

            def template_name_valid?
              location.to_s.end_with?(SUFFIX)
            end

            def fetch_template_content
              Gitlab::Template::GitlabCiYmlTemplate.find(template_name, project)&.content
            end
          end
        end
      end
    end
  end
end
