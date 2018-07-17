module EE
  module Admin
    module AppearancesController
      def allowed_appearance_params
        if License.feature_available?(:system_header_footer)
          super + header_footer_params
        else
          super
        end
      end

      private

      def header_footer_params
        %i[
          header_message
          footer_message
          message_background_color
          message_font_color
        ]
      end
    end
  end
end
