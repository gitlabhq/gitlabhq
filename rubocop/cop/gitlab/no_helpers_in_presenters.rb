# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Enforces that presenters don't include helpers.
      #
      # Presenters should be view-agnostic and not depend on view context.
      # Including helper modules in presenters couples them to the view layer
      # and makes them harder to test and reason about.
      #
      # @example
      #   # bad
      #   class BasePresenter
      #     include DiffHelper
      #
      #     def diffs_slice
      #       @diffs_slice ||= resource.first_diffs_slice(offset, diff_options)
      #     end
      #   end
      #
      # @example
      #   # good
      #   class BasePresenter
      #     attr_reader :diff_options
      #
      #     def initialize(diff_options)
      #       @diff_options = diff_options
      #     end
      #
      #     def diffs_slice
      #       @diffs_slice ||= resource.first_diffs_slice(offset, diff_options)
      #     end
      #   end
      #
      class NoHelpersInPresenters < RuboCop::Cop::Base
        DOC_LINK = 'https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/presenters/README.md#what-not-to-do-with-presenters'
        MSG = "Do not use helpers in presenters. Presenters are not aware of the view context. See #{DOC_LINK}".freeze

        RESTRICT_ON_SEND = %i[include extend require require_relative].freeze

        # @!method include_or_extend_statement?(node)
        def_node_matcher :include_or_extend_statement?, <<~PATTERN
          (send nil? {:include :extend} (const _ $_))
        PATTERN

        # @!method require_statement?(node)
        def_node_matcher :require_statement?, <<~PATTERN
          (send nil? {:require :require_relative} (str $_))
        PATTERN

        def on_send(node)
          check_include_or_extend_statement(node)
          check_require_statement(node)
        end
        alias_method :on_csend, :on_send

        private

        def check_include_or_extend_statement(node)
          include_or_extend_statement?(node) do |module_name|
            add_offense(node) if helper_module?(module_name)
          end
        end

        def check_require_statement(node)
          require_statement?(node) do |required_file|
            add_offense(node) if helper_file?(required_file)
          end
        end

        def helper_module?(module_name)
          name = module_name.to_s
          name.end_with?('Helper', 'Helpers') || name.include?('::Helper')
        end

        def helper_file?(file_path)
          return true if file_path.include?('/helpers/')

          filename = File.basename(file_path, '.*')
          filename.end_with?('_helper', '_helpers')
        end
      end
    end
  end
end
