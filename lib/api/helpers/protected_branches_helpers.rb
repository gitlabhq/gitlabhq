# frozen_string_literal: true

module API
  module Helpers
    module ProtectedBranchesHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ee do
      end
    end
  end
end
