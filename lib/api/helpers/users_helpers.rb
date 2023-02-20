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

      def model_errors(model)
        super.tap do |errors|
          # Remapping errors from nested associations.
          next unless errors.has_key?(:"user_detail.bio")

          errors.delete(:"user_detail.bio").each do |message|
            errors.add(:bio, message)
          end
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
