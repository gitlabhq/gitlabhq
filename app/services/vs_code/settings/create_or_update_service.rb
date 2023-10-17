# frozen_string_literal: true

module VsCode
  module Settings
    class CreateOrUpdateService
      def initialize(current_user:, params: {})
        @current_user = current_user
        @params = params
      end

      def execute
        # The GitLab VSCode settings API does not support creating or updating
        # machines.
        return ServiceResponse.success(payload: DEFAULT_MACHINE) if @params[:setting_type] == 'machines'

        setting = VsCodeSetting.by_user(current_user).by_setting_type(params[:setting_type]).first

        if setting.nil?
          merged_params = params.merge(user: current_user, uuid: SecureRandom.uuid)
          setting = VsCodeSetting.new(merged_params)
        else
          setting.content = params[:content]
          setting.uuid = SecureRandom.uuid
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

      private

      attr_reader :current_user, :params
    end
  end
end
