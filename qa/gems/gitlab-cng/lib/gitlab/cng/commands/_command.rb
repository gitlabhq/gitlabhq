# frozen_string_literal: true

module Gitlab
  module Cng
    module Commands
      # Thor command base class
      #
      class Command < Thor
        include Helpers::Output

        class_option :force_color,
          desc: "Force color output. Additionally can be set via CNG_FORCE_COLOR environment variable.",
          type: :boolean

        check_unknown_options!

        private

        # Options hash with symbolized keys
        #
        # @return [Hash]
        def symbolized_options
          @symbolized_options ||= options.transform_keys(&:to_sym)
        end
      end
    end
  end
end
