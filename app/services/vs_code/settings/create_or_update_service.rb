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

        setting = VsCodeSetting.by_user(current_user)
        additional_params = { uuid: SecureRandom.uuid }

        if params[:setting_type] == EXTENSIONS
          setting = setting.by_setting_types([EXTENSIONS], settings_context_hash).first
          additional_params[:settings_context_hash] = settings_context_hash
        else
          setting = setting.by_setting_types([params[:setting_type]]).first
        end

        create_or_update(setting: setting, additional_params: additional_params)
      end

      private

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
