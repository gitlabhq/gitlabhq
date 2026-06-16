# frozen_string_literal: true

module Resolvers
  module Users
    class EventsResolver < BaseResolver
      type ::Types::EventType.connection_type, null: true

      alias_method :target_user, :object

      argument :filter, ::Types::Users::EventFilterEnum,
        required: false,
        description: 'Filter events by type. Defaults to all events.'

      # `EventType` authorizes each node with `read_event`, which resolves the
      # event's `permission_object` (its target for targeted events) and checks
      # the parent project. The finder preloads each event's `target`, but not
      # the target's project, so authorizing targeted events would issue a
      # project (and namespace) lookup per node. Preload them per target class
      # here, since the project association differs (`MergeRequest#project` is an
      # alias for `:target_project`).
      before_connection_authorization do |events, current_user|
        projects = events.filter_map(&:project)
        project_associations = %i[project target_project]

        events.filter_map(&:target).group_by(&:class).each do |target_class, targets|
          association = project_associations.find { |name| target_class.reflect_on_association(name) }
          next unless association

          ActiveRecord::Associations::Preloader.new(
            records: targets,
            associations: { association => [:namespace, :project_feature] }
          ).call

          projects.concat(targets.filter_map(&association))
        end

        ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects.uniq, current_user).execute
      end

      def resolve(filter: nil)
        ::UserRecentEventsFinder.new(
          current_user,
          target_user,
          ::EventFilter.new(filter)
        ).execute
      end
    end
  end
end

Resolvers::Users::EventsResolver.prepend_mod
