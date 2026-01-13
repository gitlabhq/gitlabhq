# frozen_string_literal: true

module API
  module Entities
    # Serializes a Licensee::License
    class License < Entities::LicenseBasic
      expose :popular?, as: :popular, documentation: { type: 'Boolean' }

      expose :description, documentation: { type: 'String', example: 'A simple license' } do |license|
        license.meta['description']
      end

      expose :conditions, documentation: { type: 'String', is_array: true, example: 'include-copyright' } do |license|
        license.meta['conditions']
      end

      expose :permissions, documentation: { type: 'String', is_array: true, example: 'commercial-use' } do |license|
        license.meta['permissions']
      end

      expose :limitations, documentation: { type: 'String', is_array: true, example: 'liability' } do |license|
        license.meta['limitations']
      end

      expose :content, documentation: { type: 'String', example: 'GNU GENERAL PUBLIC LICENSE' }
    end
  end
end
