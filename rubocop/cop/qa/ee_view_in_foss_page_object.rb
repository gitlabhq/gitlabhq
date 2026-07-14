# frozen_string_literal: true

require_relative '../../qa_helpers'

module RuboCop
  module Cop
    module QA
      # Flags `view 'ee/...'` declarations in FOSS page objects (`qa/qa/page/`),
      # where the `ee/` partial does not exist and selectors validation fails in
      # the as-if-foss pipeline. Move the view into a `qa/qa/ee/page/` extension.
      #
      # @example
      #
      #   # bad - declared in a FOSS page object (qa/qa/page/profile.rb)
      #   class Profile < Page::Base
      #     view 'ee/app/views/_ee_only.html.haml' do
      #       element 'country'
      #     end
      #   end
      #
      #   # good - moved into a prepended EE extension (qa/qa/ee/page/profile.rb)
      #   module QA::EE::Page::Profile
      #     view 'ee/app/views/_ee_only.html.haml' do
      #       element 'country'
      #     end
      #   end
      class EeViewInFossPageObject < RuboCop::Cop::Base
        include QAHelpers

        MESSAGE = "Don't declare an `ee/` view in a FOSS page object. " \
          "Move this view (and the methods that use it) into " \
          "a `qa/qa/ee/page/` extension instead."

        def on_send(node)
          return unless node.method?(:view)
          return unless in_qa_file?(node)
          return if in_ee_qa_file?(node)

          path_arg = node.first_argument
          return unless path_arg&.str_type?
          return unless path_arg.value.start_with?('ee/')

          add_offense(path_arg, message: MESSAGE)
        end

        alias_method :on_csend, :on_send

        private

        def in_ee_qa_file?(node)
          path = node.source_range.source_buffer.name

          path.include?(File.join('qa', 'qa', 'ee') + File::SEPARATOR)
        end
      end
    end
  end
end
