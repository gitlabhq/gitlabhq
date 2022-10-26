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

      def model_error_messages(model)
        super.tap do |error_messages|
          # Remapping errors from nested associations.
          error_messages[:bio] = error_messages.delete(:"user_detail.bio") if error_messages.has_key?(:"user_detail.bio")
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_user_by_id(params)
        id = params[:user_id] || params[:id]
        User.find_by(id: id) || not_found!('User')
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

API::Helpers::UsersHelpers.prepend_mod_with('API::Helpers::UsersHelpers')
