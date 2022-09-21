# frozen_string_literal: true

module API
  module Entities
    class License < Entities::LicenseBasic
      expose :popular?, as: :popular
      expose(:description) { |license| license.meta['description'] }
      expose(:conditions) { |license| license.meta['conditions'] }
      expose(:permissions) { |license| license.meta['permissions'] }
      expose(:limitations) { |license| license.meta['limitations'] }
      expose :content
    end
  end
end
