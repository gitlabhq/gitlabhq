# frozen_string_literal: true

module Integrations
  module HarborSerializers
    class ArtifactSerializer < BaseSerializer
      include WithPagination

      entity ::Integrations::HarborSerializers::ArtifactEntity
    end
  end
end
