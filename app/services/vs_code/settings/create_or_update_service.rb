# frozen_string_literal: true

module VsCode
  module Settings
    class CreateOrUpdateService
      include ::VsCode::Settings

      def initialize(current_user:, params: {})
        @current_user = current_user
        @settings_context_hash = params.delete(:settings_context_hash) || nil
        @params = params
      end

      def execute
        # The GitLab VSCode settings API does not support creating or updating
        # machines.
        return ServiceResponse.success(payload: DEFAULT_MACHINE) if params[:setting_type] == 'machines'

        settings = VsCodeSetting.by_user(current_user)
        additional_params = { uuid: SecureRandom.uuid }

        if params[:setting_type] == EXTENSIONS
          settings = settings.by_setting_types([EXTENSIONS], settings_context_hash)
          additional_params[:settings_context_hash] = settings_context_hash
        else
          settings = settings.by_setting_types([params[:setting_type]])
        end

        ApplicationRecord.transaction do
          remove_duplicate_settings(settings: settings)
          create_or_update(setting: settings.first, additional_params: additional_params)
        end
      end

      private

      def remove_duplicate_settings(settings:)
        return unless settings && settings.length > 1

        settings[1...].each(&:destroy)
      end

      def create_or_update(setting:, additional_params: {})
        if setting.nil?
          attributes = params.merge(user: current_user, **additional_params)
          setting = VsCodeSetting.new(attributes)
        else
          setting.assign_attributes(content: params[:content], **additional_params)
        end

        if setting.save
          ServiceResponse.success(payload: setting)
        else
          ServiceResponse.error(
            message: setting.errors.full_messages.to_sentence,
            payload: { setting: setting }
          )
        end
      end

      attr_reader :current_user, :settings_context_hash, :params
    end
  end
end
