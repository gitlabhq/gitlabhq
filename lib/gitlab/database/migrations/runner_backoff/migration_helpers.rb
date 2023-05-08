# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module RunnerBackoff
        module MigrationHelpers
          extend ActiveSupport::Concern

          class_methods do
            def enable_runner_backoff!
              @enable_runner_backoff = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
            end

            def enable_runner_backoff?
              !!@enable_runner_backoff
            end
          end

          delegate :enable_runner_backoff?, to: :class
        end
      end
    end
  end
end
