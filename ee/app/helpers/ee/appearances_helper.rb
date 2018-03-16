module EE
  module AppearancesHelper
    def header_message(appearance)
      return unless appearance&.show_header?

      class_names = []
      class_names << 'with-performance-bar' if performance_bar_enabled?

      render_message(appearance, :header_message, class_names)
    end

    def footer_message(appearance)
      return unless appearance&.show_footer?

      render_message(appearance, :footer_message)
    end

    private

    def render_message(appearance, field_sym, class_names = [])
      class_names << field_sym.to_s.dasherize

      content_tag :div, class: class_names, style: message_style(appearance) do
        ::Banzai.render_field(appearance, field_sym).html_safe
      end
    end

    def message_style(appearance)
      style = ''
      style << "background-color: #{appearance.background_color};"
      style << "color: #{appearance.font_color}"
      style
    end
  end
end
