# frozen_string_literal: true

module API
  module Entities
    class LicenseBasic < Grape::Entity
      expose :key, :name, :nickname
      expose :url, as: :html_url
      expose(:source_url) { |license| license.meta['source'] }
    end
  end
end
