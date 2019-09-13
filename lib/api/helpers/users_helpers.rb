# frozen_string_literal: true

module API
  module Helpers
    module UsersHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ee do
      end

      params :optional_index_params_ee do
      end
    end
  end
end

API::Helpers::UsersHelpers.prepend_if_ee('EE::API::Helpers::UsersHelpers')
