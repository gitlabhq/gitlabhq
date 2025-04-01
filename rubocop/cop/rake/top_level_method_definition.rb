# frozen_string_literal: true

module RuboCop
  module Cop
    module Rake
      # Checks for method, class, and module definitions in rake task files
      # that could cause namespace collisions or code organization issues.
      #
      # This cop flags:
      # 1. Method definitions directly inside rake namespaces
      # 2. Any class definitions in rake files
      # 3. Any module definitions in rake files
      #
      # The ideal pattern is to move all supporting code to standalone Ruby files
      # rather than defining methods, classes or modules in rake files at all.
      #
      # @example
      #   # bad - method definition inside rake namespace
      #   namespace :gitlab do
      #     namespace :elastic do
      #       def task_executor_service
      #         Search::RakeTaskExecutorService.new(logger: stdout_logger)
      #       end
      #     end
      #   end
      #
      #   # bad - class definition in rake file
      #   # Either inside namespaces or at top level
      #   class TaskHelper
      #     def self.task_executor_service
      #       Search::RakeTaskExecutorService.new(logger: stdout_logger)
      #     end
      #   end
      #
      #   # bad - module definition in rake file
      #   # Either inside namespaces or at top level
      #   module Search
      #     module RakeTask
      #       module Elastic
      #         def self.task_executor_service
      #           Search::RakeTaskExecutorService.new(logger: stdout_logger)
      #         end
      #       end
      #     end
      #   end
      #
      #   # good - use a separate Ruby file for supporting code
      #   # In ee/lib/search/rake_task/elastic.rb:
      #   module Search
      #     module RakeTask
      #       module Elastic
      #         def self.task_executor_service
      #           Search::RakeTaskExecutorService.new(logger: stdout_logger)
      #         end
      #       end
      #     end
      #   end
      #
      #   # In the rake file, use the module:
      #   namespace :gitlab do
      #     namespace :elastic do
      #       desc 'GitLab | Elasticsearch | Info'
      #       task info: :environment do
      #         Gitlab::Search::RakeTask::Elastic.task_executor_service.execute(:info)
      #       end
      #     end
      #   end
      class TopLevelMethodDefinition < RuboCop::Cop::Base
        MSG = 'Methods defined in rake tasks share the same namespace and can cause collisions. ' \
          'Please define it in a bounded contexts module in a separate Ruby file. ' \
          'For example, Search::RakeTask::<Namespace>. ' \
          'See https://github.com/rubocop/rubocop-rake/issues/42'
        CLASS_MSG = 'Classes should not be defined in rake files. ' \
          'Please define it in a bounded contexts module in a separate Ruby file. ' \
          'For example, Search::RakeTask::<Namespace>. ' \
          'See https://github.com/rubocop/rubocop-rake/issues/42'
        MODULE_MSG = 'Modules should not be defined in rake files. ' \
          'Please define it in a separate Ruby file. For example, Search::RakeTask::<Namespace>. ' \
          'See https://github.com/rubocop/rubocop-rake/issues/42'

        def on_def(node)
          return unless in_rake_file?

          add_offense(node)
        end

        def on_defs(node)
          return unless in_rake_file?

          add_offense(node)
        end

        def on_class(node)
          return unless in_rake_file?

          add_offense(node, message: CLASS_MSG)
        end

        def on_module(node)
          return unless in_rake_file?

          add_offense(node, message: MODULE_MSG)
        end

        private

        def in_rake_file?
          processed_source.file_path.end_with?('.rake')
        end
      end
    end
  end
end
