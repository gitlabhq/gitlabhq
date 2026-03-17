# frozen_string_literal: true

module Layouts
  class IndexLayoutPreview < ViewComponent::Preview
    # @param heading text
    # @param description text
    def default(
      heading: 'Page Title',
      description: 'This is a page description'
    )
      render(::Layouts::IndexLayout.new(heading: heading, description: description)) do
        tag.p('Index layout default slot.')
      end
    end

    def with_slots
      render(::Layouts::IndexLayout.new) do |c|
        c.with_heading do
          'Custom <i>Heading</i> with Markup'.html_safe
        end

        c.with_description do
          'Custom <i>description</i> information with Markup. <a href="#">Learn more</a>'.html_safe
        end

        tag.p('Index layout default slot.')
      end
    end

    # @param heading text
    # @param description text
    def with_alerts(
      heading: 'Page Title',
      description: 'This is a page description'
    )
      render(::Layouts::IndexLayout.new(heading: heading, description: description)) do |c|
        c.with_alerts do
          c.safe_join([
            c.render(Pajamas::AlertComponent.new(variant: :danger, title: 'Example danger alert title')) do |a|
              a.with_body { 'Example alert content' }
            end,
            c.render(Pajamas::AlertComponent.new(variant: :warning, title: 'Example warning alert title')) do |a|
              a.with_body { 'Example alert content' }
            end,
            c.render(Pajamas::AlertComponent.new(variant: :info, title: 'Example info alert title')) do |a|
              a.with_body { 'Example alert content' }
            end
          ])
        end

        tag.p('Index layout default slot.')
      end
    end
  end
end
