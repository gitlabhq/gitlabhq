module ActionView
  module Template::Handlers
    class Markdown
      class_attribute :default_format
      self.default_format = Mime::HTML

      def call(template)
        @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                                              no_intra_emphasis: true,
                                              tables: true,
                                              fenced_code_blocks: true,
                                              autolink: true,
                                              strikethrough: true,
                                              lax_spacing: true,
                                              space_after_headers: true,
                                              superscript: true)
        "#{@markdown.render(template.source).inspect}.html_safe"
      end
    end
  end
end

ActionView::Template.register_template_handler(:md, ActionView::Template::Handlers::Markdown.new)
