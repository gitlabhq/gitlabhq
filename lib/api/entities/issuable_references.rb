# frozen_string_literal: true

module API
  module Entities
    class IssuableReferences < Grape::Entity
      expose :short, documentation: { type: 'String', example: "&6" } do |issuable|
        issuable.to_reference
      end

      expose :relative, documentation: { type: 'String', example: "&6" } do |issuable, options|
        issuable.to_reference(options[:group] || options[:project])
      end

      expose :full, documentation: { type: 'String', example: "test&6" } do |issuable|
        issuable.to_reference(full: true)
      end
    end
  end
end
