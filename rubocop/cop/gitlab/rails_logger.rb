# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      class RailsLogger < ::RuboCop::Cop::Cop
        include CodeReuseHelpers

        # This cop checks for the Rails.logger in the codebase
        #
        # @example
        #
        #   # bad
        #   Rails.logger.error("Project #{project.full_path} could not be saved")
        #
        #   # good
        #   Gitlab::AppLogger.error("Project %{project_path} could not be saved" % { project_path: project.full_path })
        MSG = 'Use a structured JSON logger instead of `Rails.logger`. ' \
          'https://docs.gitlab.com/ee/development/logging.html'.freeze

        def_node_matcher :rails_logger?, <<~PATTERN
          (send (const nil? :Rails) :logger ... )
        PATTERN

        WHITELISTED_DIRECTORIES = %w[
          spec
        ].freeze

        def on_send(node)
          return if in_whitelisted_directory?(node)
          return unless rails_logger?(node)

          add_offense(node, location: :expression)
        end

        def in_whitelisted_directory?(node)
          path = file_path_for_node(node)

          WHITELISTED_DIRECTORIES.any? do |directory|
            path.start_with?(
              File.join(rails_root, directory),
              File.join(rails_root, 'ee', directory)
            )
          end
        end
      end
    end
  end
end
