# frozen_string_literal: true

module Integrations
  module HarborSerializers
    class TagSerializer < BaseSerializer
      include WithPagination

      entity ::Integrations::HarborSerializers::TagEntity
    end
  end
end
