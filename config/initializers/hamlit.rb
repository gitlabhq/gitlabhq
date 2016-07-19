module Hamlit
  class TemplateHandler
    def call(template)
      Engine.new(
        generator: Temple::Generators::RailsOutputBuffer,
        attr_quote: '"',
      ).call(template.source)
    end
  end
end

ActionView::Template.register_template_handler(
  :haml,
  Hamlit::TemplateHandler.new,
)

Hamlit::Filters.remove_filter('coffee')
Hamlit::Filters.remove_filter('coffeescript')
