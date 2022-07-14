# frozen_string_literal: true

module Integrations
  module HarborSerializers
    class RepositorySerializer < BaseSerializer
      include WithPagination

      entity ::Integrations::HarborSerializers::RepositoryEntity
    end
  end
end
