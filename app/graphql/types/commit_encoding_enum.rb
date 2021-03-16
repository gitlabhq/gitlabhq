# frozen_string_literal: true

module Types
  class CommitEncodingEnum < BaseEnum
    graphql_name 'CommitEncoding'

    value 'TEXT', description: 'Text encoding.', value: :text
    value 'BASE64', description: 'Base64 encoding.', value: :base64
  end
end
