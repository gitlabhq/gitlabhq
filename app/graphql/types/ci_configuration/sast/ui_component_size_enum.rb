# frozen_string_literal: true

module Types
  module CiConfiguration
    module Sast
      class UiComponentSizeEnum < BaseEnum
        graphql_name 'SastUiComponentSize'
        description 'Size of UI component in SAST configuration page'

        value 'SMALL', description: "Size of UI component in SAST configuration page is small."
        value 'MEDIUM', description: "Size of UI component in SAST configuration page is medium."
        value 'LARGE', description: "Size of UI component in SAST configuration page is large."
      end
    end
  end
end
