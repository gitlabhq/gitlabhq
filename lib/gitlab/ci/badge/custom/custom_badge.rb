# frozen_string_literal: true

module Gitlab
  module Ci
    module Badge
      module Custom
        class CustomBadge < Badge::Base
          attr_reader :project, :customization

          def initialize(project, opts: {})
            @project = project
            @customization = {
              key_width: opts[:key_width] ? opts[:key_width].to_i : nil,
              key_text: opts[:key_text],
              key_color: opts[:key_color],
              value_color: opts[:value_color],
              value_text: opts[:value_text],
              value_width: opts[:value_width] ? opts[:value_width].to_i : nil
            }
          end

          def entity
            'custom'
          end

          def metadata
            @metadata ||= Custom::Metadata.new(self)
          end

          def template
            @template ||= Custom::Template.new(self)
          end
        end
      end
    end
  end
end
