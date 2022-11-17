# frozen_string_literal: true

module API
  module Entities
    # Serializes a Licensee::License
    class License < Entities::LicenseBasic
      expose :popular?, as: :popular, documentation: { type: 'boolean' }

      expose :description, documentation: { type: 'string', example: 'A simple license' } do |license|
        license.meta['description']
      end

      expose :conditions, documentation: { type: 'string', is_array: true, example: 'include-copyright' } do |license|
        license.meta['conditions']
      end

      expose :permissions, documentation: { type: 'string', is_array: true, example: 'commercial-use' } do |license|
        license.meta['permissions']
      end

      expose :limitations, documentation: { type: 'string', is_array: true, example: 'liability' } do |license|
        license.meta['limitations']
      end

      expose :content, documentation: { type: 'string', example: 'GNU GENERAL PUBLIC LICENSE' }
    end
  end
end
