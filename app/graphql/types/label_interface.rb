# frozen_string_literal: true

module Types
  module LabelInterface # rubocop:disable Gitlab/BoundedContexts -- existing Label modules/classes are not bounded
    include BaseInterface

    field :color, GraphQL::Types::String, null: false,
      description: 'Background color of the label.'
    field :created_at, Types::TimeType, null: false,
      description: 'When the label was created.'
    field :description,
      GraphQL::Types::String,
      null: true,
      description: 'Description of the label (Markdown rendered as HTML for caching).',
      scopes: [:api, :read_api, :ai_workflows]
    field :text_color, GraphQL::Types::String, null: false,
      description: 'Text color of the label.'
    field :title, GraphQL::Types::String, null: false,
      description: 'Content of the label.',
      scopes: [:api, :read_api, :ai_workflows]
    field :updated_at, Types::TimeType, null: false,
      description: 'When the label was last updated.'
  end
end
