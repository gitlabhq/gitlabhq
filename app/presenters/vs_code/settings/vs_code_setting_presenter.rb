# frozen_string_literal: true

module VsCode
  module Settings
    class VsCodeSettingPresenter < Gitlab::View::Presenter::Simple
      attr_reader :setting

      def initialize(setting)
        @setting = setting
      end

      def content
        @setting[:setting_type] == 'machines' ? nil : @setting.content
      end

      def machines
        @setting[:setting_type] == 'machines' ? @setting[:machines] : nil
      end

      def version
        @setting[:version]
      end

      def machine_id
        DEFAULT_MACHINE[:uuid] if @setting[:setting_type] != 'machines'
      end
    end
  end
end
