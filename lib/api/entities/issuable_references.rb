# frozen_string_literal: true

module API
  module Entities
    class IssuableReferences < Grape::Entity
      expose :short do |issuable|
        issuable.to_reference
      end

      expose :relative do |issuable, options|
        issuable.to_reference(options[:group] || options[:project])
      end

      expose :full do |issuable|
        issuable.to_reference(full: true)
      end
    end
  end
end
