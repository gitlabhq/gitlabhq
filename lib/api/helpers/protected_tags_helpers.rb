# frozen_string_literal: true

module API
  module Helpers
    module ProtectedTagsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ce do
        optional :allowed_to_create, type: Array[JSON],
          desc: 'Array of deploy keys allowed to create protected tags' do
          optional :deploy_key_id, type: Integer, desc: 'ID of a deploy key'
        end
      end

      params :optional_params_ee do
      end

      params :optional_params do
        use :optional_params_ce
        use :optional_params_ee
      end
    end
  end
end

API::Helpers::ProtectedTagsHelpers.prepend_mod_with('API::Helpers::ProtectedTagsHelpers')
