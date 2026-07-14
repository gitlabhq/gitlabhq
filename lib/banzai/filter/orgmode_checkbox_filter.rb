# frozen_string_literal: true

module Banzai
  module Filter
    # Converts checkbox markers (`[ ]`, `[X]`, `[-]`) inside <li>
    # elements into <input type="checkbox"> elements with appropriate attributes,
    # matching the HTML structure produced by Markdown's task list rendering.
    class OrgmodeCheckboxFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      # Matches a checkbox marker at the beginning of a text node:
      #   [ ]  unchecked
      #   [X]  checked
      #   [-]  indeterminate (partially done)
      CHECKBOX_PATTERN = /\A\[([ X-])\](?:[ \t]+(.*))?\z/m

      CHECKBOX_ATTRS = {
        'X' => { 'checked' => 'checked' },
        '-' => { 'data-indeterminate' => 'true' }
      }.freeze

      def call
        doc.css('li').first(Banzai::Filter::FILTER_ITEM_LIMIT).each do |li|
          convert_checkbox(li)
        end

        doc
      end

      private

      def convert_checkbox(li)
        return if li['class']

        first_child = li.children.first
        return unless first_child&.text?

        match = first_child.content.match(CHECKBOX_PATTERN)
        return unless match

        state = match[1]
        first_child.content = match[2].to_s

        input = create_checkbox_input(state)
        li.prepend_child(input)
        li['class'] = 'task-list-item'

        parent = li.parent
        parent['class'] ||= 'task-list' if parent.name == 'ul' || parent.name == 'ol'
        # SanitizationFilter only allows exact class values
        # ("task-list" for <ul>/<ol>, "task-list-item" for <li>).
      end

      def create_checkbox_input(state)
        input = doc.document.create_element('input',
          type: 'checkbox',
          class: 'task-list-item-checkbox',
          disabled: 'disabled'
        )

        CHECKBOX_ATTRS[state]&.each { |k, v| input[k] = v }

        input
      end
    end
  end
end
