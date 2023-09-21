# frozen_string_literal: true

module VsCode
  module Settings
    class CreateOrUpdateService
      def initialize(current_user:, params: {})
        @current_user = current_user
        @params = params
      end

      def execute
        setting = VsCode::VsCodeSetting.by_user(current_user).by_setting_type(params[:setting_type]).first

        if setting.nil?
          merged_params = params.merge(user: current_user)
          setting = VsCode::VsCodeSetting.new(merged_params)
        else
          setting.content = params[:content]
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
