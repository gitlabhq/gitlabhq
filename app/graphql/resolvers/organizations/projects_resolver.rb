# frozen_string_literal: true

module Resolvers
  module Organizations
    class ProjectsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::ProjectType, null: true

      authorize :read_project

      alias_method :organization, :object

      def resolve
        ::ProjectsFinder.new(current_user: current_user, params: { organization: organization }).execute
      end
    end
  end
end
