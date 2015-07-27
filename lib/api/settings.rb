module API
  class Settings < Grape::API
    before { authenticated_as_admin! }

    helpers do
      def current_settings
        @current_setting ||=
          (ApplicationSetting.current || ApplicationSetting.create_from_defaults)
      end
    end

    # Get current applicaiton settings
    #
    # Example Request:
    #   GET /application/settings
    get "application/settings" do
      present current_settings, with: Entities::ApplicationSetting
    end

    # Modify applicaiton settings
    #
    # Example Request:
    #   PUT /application/settings
    put "application/settings" do
      attributes = current_settings.attributes.keys - ["id"]
      attrs = attributes_for_keys(attributes)

      if current_settings.update_attributes(attrs)
        present current_settings, with: Entities::ApplicationSetting
      else
        render_validation_error!(current_settings)
      end
    end
  end
end
