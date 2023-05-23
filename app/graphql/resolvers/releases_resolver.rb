# frozen_string_literal: true

module Resolvers
  class ReleasesResolver < BaseResolver
    type Types::ReleaseType.connection_type, null: true

    argument :sort, Types::ReleaseSortEnum,
             required: false, default_value: :released_at_desc,
             description: 'Sort releases by given criteria.'

    # This resolver has a custom singular resolver
    def self.single
      Resolvers::ReleaseResolver
    end

    SORT_TO_PARAMS_MAP = {
      released_at_desc: { order_by: 'released_at', sort: 'desc' },
      released_at_asc: { order_by: 'released_at', sort: 'asc' },
      created_desc: { order_by: 'created_at', sort: 'desc' },
      created_asc: { order_by: 'created_at', sort: 'asc' }
    }.freeze

    def resolve(sort:)
      BatchLoader::GraphQL.for(project).batch do |projects, loader|
        releases = ReleasesFinder.new(
          projects,
          current_user,
          SORT_TO_PARAMS_MAP[sort]
        ).execute

        # group_by will not cause N+1 queries here because ReleasesFinder preloads projects
        releases.group_by(&:project).each do |project, versions|
          loader.call(project, versions)
        end
      end
    end

    private

    def project
      object.respond_to?(:project) ? object.project : object
    end
  end
end
