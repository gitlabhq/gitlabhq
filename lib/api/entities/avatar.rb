# frozen_string_literal: true

module API
  module Entities
    class Avatar < Grape::Entity
      expose :avatar_url do |avatarable, options|
        avatarable.avatar_url(only_path: false, size: options[:size])
      end
    end
  end
end
