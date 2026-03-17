# frozen_string_literal: true

module API
  module Ci
    module Helpers
      module RunnerHelpers
        extend ActiveSupport::Concern
        extend Grape::API::Helpers

        params :create_runner_params_ee do # rubocop:disable Lint/EmptyBlock -- Overridden in EE
        end
      end
    end
  end
end

API::Ci::Helpers::RunnerHelpers.prepend_mod_with('API::Ci::Helpers::RunnerHelpers')
