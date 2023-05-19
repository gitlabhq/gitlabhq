# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class Parameter < Source
        def content
          strong_memoize(:content) do
            next unless custom_content.present?

            custom_content
          end
        end

        def source
          :parameter_source
        end
      end
    end
  end
end
