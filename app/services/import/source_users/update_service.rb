# frozen_string_literal: true

module Import
  module SourceUsers
    class UpdateService
      def initialize(import_source_user, params)
        @import_source_user = import_source_user
        @params = params
      end

      def execute
        discard_non_blank_attributes

        ServiceResponse.success(payload: import_source_user) if params.empty?

        assign_attributes_to_source_user

        placeholder_user = import_source_user.placeholder_user

        if placeholder_user&.placeholder?
          result = update_placeholder_user(placeholder_user)

          if result[:status] == :error
            return ServiceResponse.error(payload: import_source_user, message: result[:message])
          end
        end

        if import_source_user.save
          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(
            payload: import_source_user,
            message: import_source_user.errors.full_messages.join(', ')
          )
        end
      end

      private

      attr_reader :import_source_user, :params

      def discard_non_blank_attributes
        # Delete attributes that are present, as other concurrent migrations
        # targeting the same top-level group may have already updated the
        # source user and there is not reason to update it again.
        params.delete(:source_name) if import_source_user.source_name.present?
        params.delete(:source_username) if import_source_user.source_username.present?
      end

      def update_placeholder_user(user)
        Users::UpdateService.new(user, update_params.merge(user: user)).execute
      end

      # overridden in EE
      def update_params
        placeholder_creator = Gitlab::Import::PlaceholderUserCreator.new(import_source_user)

        update_params = {}
        update_params[:name] = placeholder_creator.placeholder_name if params[:source_name]

        if params[:source_username]
          update_params[:username] = placeholder_creator.send(:username_and_email_generator).username # rubocop:disable GitlabSecurity/PublicSend -- Safe to call, we don't want to publically expose this method.
        end

        update_params
      end

      def assign_attributes_to_source_user
        import_source_user.assign_attributes({
          source_name: params[:source_name],
          source_username: params[:source_username]
        }.compact)
      end
    end
  end
end

Import::SourceUsers::UpdateService.prepend_mod
