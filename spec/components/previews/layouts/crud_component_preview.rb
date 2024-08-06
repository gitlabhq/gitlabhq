# frozen_string_literal: true

module Layouts
  class CrudComponentPreview < ViewComponent::Preview
    # @param title text
    # @param description text
    # @param count number
    # @param icon text
    # @param toggle_text text
    # rubocop:disable Metrics/ParameterLists -- allow all params
    def default(
      title: 'CRUD Component title',
      description: 'Description',
      count: 99,
      icon: 'rocket',
      icon_class: 'gl-text-success',
      toggle_text: 'Add action',
      actions: 'Custom actions',
      body: 'Body slot',
      form: 'Form slot',
      footer: 'Footer slot',
      pagination: 'Pagination slot'
    )
      render(::Layouts::CrudComponent.new(
        title,
        description: description,
        count: count,
        icon: icon,
        icon_class: icon_class,
        toggle_text: toggle_text)) do |c|
        c.with_description { description }
        c.with_actions { actions }
        c.with_body { body }
        c.with_form { form }
        c.with_footer { footer }
        c.with_pagination { pagination }
      end
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
