module EE
  module Admin
    module AppearancesController
      def allowed_appearance_params
        super + %i[
          header_message
          footer_message
          message_background_color
          message_font_color
        ]
      end
    end
  end
end
