# frozen_string_literal: true

module Types
  class ShaFormatEnum < BaseEnum
    graphql_name 'ShaFormat'
    description 'How to format SHA strings.'

    FORMATS_DESCRIPTION = {
      short: 'Abbreviated format. Short SHAs are typically eight characters long.',
      long: 'Unabbreviated format.'
    }.freeze

    FORMATS_DESCRIPTION.each do |format, description|
      value format.to_s.upcase,
        description: description,
        value: format.to_s
    end
  end
end
