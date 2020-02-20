# frozen_string_literal: true

module API
  module Entities
    class IssuableEntity < Grape::Entity
      expose :id, :iid
      expose(:project_id) { |entity| entity&.project.try(:id) }
      expose :title, :description
      expose :state, :created_at, :updated_at

      # Avoids an N+1 query when metadata is included
      def issuable_metadata(subject, options, method, args = nil)
        cached_subject = options.dig(:issuable_metadata, subject.id)
        (cached_subject || subject).public_send(method, *args) # rubocop: disable GitlabSecurity/PublicSend
      end
    end
  end
end
