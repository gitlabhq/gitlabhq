# frozen_string_literal: true

module EE
  module Mentionable
    module ReferenceRegexes
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :other_patterns
        def other_patterns
          [
            ::Epic.reference_pattern,
            *super
          ]
        end
      end
    end
  end
end
