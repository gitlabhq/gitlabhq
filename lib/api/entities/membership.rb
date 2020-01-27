# frozen_string_literal: true

module API
  module Entities
    class Membership < Grape::Entity
      expose :source_id
      expose :source_name do |member|
        member.source.name
      end
      expose :source_type
      expose :access_level
    end
  end
end
