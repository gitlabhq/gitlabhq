# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      class RailsLogger < ::RuboCop::Cop::Cop
        include CodeReuseHelpers

        # This cop checks for the Rails.logger log methods in the codebase
        #
        # @example
        #
        #   # bad
        #   Rails.logger.error("Project #{project.full_path} could not be saved")
        #
        #   # good
        #   Gitlab::AppLogger.error("Project %{project_path} could not be saved" % { project_path: project.full_path })
        #
        #   # OK
        #   Rails.logger.level
        MSG = 'Use a structured JSON logger instead of `Rails.logger`. ' \
          'https://docs.gitlab.com/ee/development/logging.html'

        # See supported log methods:
        # https://ruby-doc.org/stdlib-2.6.6/libdoc/logger/rdoc/Logger.html
        LOG_METHODS = %i[debug error fatal info warn].freeze
        LOG_METHODS_PATTERN = LOG_METHODS.map(&:inspect).join(' ').freeze

        def_node_matcher :rails_logger_log?, <<~PATTERN
          (send
            (send (const nil? :Rails) :logger)
            {#{LOG_METHODS_PATTERN}} ...
          )
        PATTERN

        def on_send(node)
          return unless rails_logger_log?(node)

          add_offense(node, location: :expression)
        end
      end
    end
  end
end
