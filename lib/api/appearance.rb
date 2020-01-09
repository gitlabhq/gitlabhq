# frozen_string_literal: true

module API
  class Appearance < Grape::API
    before { authenticated_as_admin! }

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
    end
    params do
      optional :title, type: String, desc: 'Instance title on the sign in / sign up page'
      optional :description, type: String, desc: 'Markdown text shown on the sign in / sign up page'
      # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
      optional :logo, type: File, desc: 'Instance image used on the sign in / sign up page' # rubocop:disable Scalability/FileUploads
      optional :header_logo, type: File, desc: 'Instance image used for the main navigation bar' # rubocop:disable Scalability/FileUploads
      optional :favicon, type: File, desc: 'Instance favicon in .ico/.png format' # rubocop:disable Scalability/FileUploads
      optional :new_project_guidelines, type: String, desc: 'Markmarkdown text shown on the new project page'
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
