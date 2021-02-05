# frozen_string_literal: true

module Types
  module CiConfiguration
    module Sast
      class UiComponentSizeEnum < BaseEnum
        graphql_name 'SastUiComponentSize'
        description 'Size of UI component in SAST configuration page'

        value 'SMALL'
        value 'MEDIUM'
        value 'LARGE'
      end
    end
  end
end
