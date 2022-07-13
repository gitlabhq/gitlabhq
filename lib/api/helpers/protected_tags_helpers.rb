# frozen_string_literal: true

module API
  module Helpers
    module ProtectedTagsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ee do
      end
    end
  end
end

API::Helpers::ProtectedTagsHelpers.prepend_mod_with('API::Helpers::ProtectedTagsHelpers')
