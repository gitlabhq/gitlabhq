# frozen_string_literal: true

module Mutations
  module Admin
    module AbuseReportLabels
      class Create < BaseMutation
        graphql_name 'AbuseReportLabelCreate'

        field :label, Types::AntiAbuse::AbuseReportLabelType, null: true, description: 'Label after mutation.'

        argument :title, GraphQL::Types::String, required: true, description: 'Title of the label.'

        argument :color, GraphQL::Types::String, required: false, default_value: Label::DEFAULT_COLOR,
          see: {
            'List of color keywords at mozilla.org' =>
              'https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords'
          },
          description: <<~DESC
            The color of the label given in 6-digit hex notation with leading '#' sign
            (for example, `#FFAABB`) or one of the CSS color names.
          DESC

        def resolve(args)
          raise_resource_not_available_error! unless current_user.can?(:admin_all_resources)

          label = ::Admin::AbuseReportLabels::CreateService.new(args).execute

          {
            label: label.persisted? ? label : nil,
            errors: errors_on_object(label)
          }
        end
      end
    end
  end
end
