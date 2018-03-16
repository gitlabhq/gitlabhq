module EE
  module Admin
    module AppearancesController
      def allowed_appearance_params
        super + %i[
          header_message
          footer_message
          background_color
          font_color
        ]
      end
    end
  end
end
