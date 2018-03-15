module EE
  module Admin
    module AppearancesController
      def appearance_params_attributes
        super + appearance_params_ee
      end

      private

      def appearance_params_ee
        %i[
          header_message
          footer_message
          background_color
          font_color
        ]
      end
    end
  end
end
