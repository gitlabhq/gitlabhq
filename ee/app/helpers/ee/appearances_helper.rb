module EE
  module AppearancesHelper
    def header_message(appearance)
      return unless appearance&.header_message.present?

      class_names = []
      class_names << 'with-performance-bar' if performance_bar_enabled?

      appearance_message(appearance, :header_message, class_names)
    end

    def footer_message(appearance)
      return unless appearance&.footer_message.present?

      appearance_message(appearance, :footer_message)
    end

    private

    def appearance_message(appearance, field_sym, class_names = [])
      class_names << field_sym.to_s.dasherize

      content_tag :div, class: class_names, style: message_style(appearance) do
        render_message(appearance, field_sym)
      end
    end

    def message_style(appearance)
      style = ''
      style << "background-color: #{appearance.background_color};"
      style << "color: #{appearance.font_color}"
      style
    end

    def render_message(appearance, field)
      ::Banzai.render_field(appearance, field).html_safe
    end
  end
end
