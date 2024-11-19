# frozen_string_literal: true

module API
  module Entities
    class Tag < Grape::Entity
      include RequestAwareEntity

      expose :name, documentation: { type: 'string', example: 'v1.0.0' }
      expose :message, documentation: { type: 'string', example: 'Release v1.0.0' }
      expose :target, documentation: { type: 'string', example: '2695effb5807a22ff3d138d593fd856244e155e7' }

      expose :commit, using: Entities::Commit do |repo_tag, options|
        options[:project].repository.commit(repo_tag.dereferenced_target)
      end

      expose :release, using: Entities::TagRelease, if: ->(*) { can_read_release? } do |repo_tag, options|
        options[:releases]&.find { |r| r.tag == repo_tag.name }
      end
      expose :protected, documentation: { type: 'boolean', example: true } do |repo_tag, options|
        ::ProtectedTag.protected?(options[:project], repo_tag.name)
      end

      expose :date, as: :created_at, documentation: { type: 'dateTime', example: '2023-10-12T02:16:52.000Z' }

      def can_read_release?
        can?(options[:current_user], :read_release, options[:project])
      end
    end
  end
end
