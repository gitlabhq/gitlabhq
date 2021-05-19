# frozen_string_literal: true

module Mutations
  module Labels
    class Create < BaseMutation
      include Mutations::ResolvesResourceParent

      graphql_name 'LabelCreate'

      field :label,
            Types::LabelType,
            null: true,
            description: 'The label after mutation.'

      argument :title, GraphQL::STRING_TYPE,
               required: true,
               description: 'Title of the label.'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description of the label.'

      argument :color, GraphQL::STRING_TYPE,
               required: false,
               default_value: Label::DEFAULT_COLOR,
               see: {
                 'List of color keywords at mozilla.org' =>
                   'https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords'
               },
               description: <<~DESC
                 The color of the label given in 6-digit hex notation with leading '#' sign
                 (for example, `#FFAABB`) or one of the CSS color names.
               DESC

      authorize :admin_label

      def resolve(args)
        parent = authorized_resource_parent_find!(args)
        parent_key = parent.is_a?(Project) ? :project : :group

        label = ::Labels::CreateService.new(args).execute(parent_key => parent)

        {
          label: label.persisted? ? label : nil,
          errors: errors_on_object(label)
        }
      end
    end
  end
end
