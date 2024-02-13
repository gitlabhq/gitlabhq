# frozen_string_literal: true

module API
  class Appearance < ::API::Base
    before { authenticated_as_admin! }

    feature_category :navigation
    urgency :low

    helpers do
      def current_appearance
        @current_appearance ||= (::Appearance.current || ::Appearance.new)
      end
    end

    desc 'Get the current appearance' do
      success Entities::Appearance
    end
    get "application/appearance" do
      present current_appearance, with: Entities::Appearance
    end

    desc 'Modify appearance' do
      success Entities::Appearance
      consumes ['multipart/form-data']
    end
    params do
      optional :title, type: String, desc: 'Instance title on the sign in / sign up page'
      optional :description, type: String, desc: 'Markdown text shown on the sign in / sign up page'
      optional :pwa_name, type: String, desc: 'Name of the Progressive Web App'
      optional :pwa_short_name, type: String, desc: 'Optional, short name for Progressive Web App'
      optional :pwa_description, type: String, desc: 'An explanation of what the Progressive Web App does'
      # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
      optional :logo, type: File, desc: 'Instance image used on the sign in / sign up page' # rubocop:todo Scalability/FileUploads
      optional :pwa_icon, type: File, desc: 'Icon used for Progressive Web App' # rubocop:todo Scalability/FileUploads
      optional :header_logo, type: File, desc: 'Instance image used for the main navigation bar' # rubocop:todo Scalability/FileUploads
      optional :favicon, type: File, desc: 'Instance favicon in .ico/.png format' # rubocop:todo Scalability/FileUploads
      optional :member_guidelines, type: String, desc: 'Markdown text shown on the members page of a group or project'
      optional :new_project_guidelines, type: String, desc: 'Markdown text shown on the new project page'
      optional :profile_image_guidelines, type: String, desc: 'Markdown text shown on the profile page below Public Avatar'
      optional :header_message, type: String, desc: 'Message within the system header bar'
      optional :footer_message, type: String, desc: 'Message within the system footer bar'
      optional :message_background_color, type: String, desc: 'Background color for the system header / footer bar'
      optional :message_font_color, type: String, desc: 'Font color for the system header / footer bar'
      optional :email_header_and_footer_enabled, type: Boolean, desc: 'Add header and footer to all outgoing emails if enabled'
    end
    put "application/appearance" do
      attrs = declared_params(include_missing: false)

      if current_appearance.update(attrs)
        present current_appearance, with: Entities::Appearance
      else
        render_validation_error!(current_appearance)
      end
    end
  end
end

API::Appearance.prepend_mod
