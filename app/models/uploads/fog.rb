# frozen_string_literal: true

module Uploads
  class Fog < Base
    include ::ObjectStorage::FogHelpers
    extend ::Gitlab::Utils::Override

    def keys(relation)
      return [] unless available?

      relation.pluck(:path)
    end

    def delete_keys(keys)
      keys.each { |key| delete_object(key) }
    end

    private

    override :storage_location_identifier
    def storage_location_identifier
      :uploads
    end
  end
end
