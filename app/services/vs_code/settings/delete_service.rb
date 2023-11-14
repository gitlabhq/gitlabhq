# frozen_string_literal: true

module VsCode
  module Settings
    class DeleteService
      def initialize(current_user:)
        @current_user = current_user
      end

      def execute
        VsCodeSetting.by_user(current_user).delete_all

        ServiceResponse.success
      end

      private

      attr_reader :current_user
    end
  end
end
