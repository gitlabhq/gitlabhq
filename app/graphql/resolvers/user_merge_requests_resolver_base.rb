# frozen_string_literal: true

module Resolvers
  class UserMergeRequestsResolverBase < MergeRequestsResolver
    include ResolvesProject

    argument :group_id,
      type: ::Types::GlobalIDType[::Group],
      required: false,
      description: <<~DESC
               The global ID of the group the authored merge requests should be in.
               Merge requests in subgroups are included.
      DESC

    argument :project_path,
      type: GraphQL::Types::String,
      required: false,
      description: <<~DESC
               The full-path of the project the authored merge requests should be in.
               Incompatible with projectId.
      DESC

    argument :project_id,
      type: ::Types::GlobalIDType[::Project],
      required: false,
      description: <<~DESC
               The global ID of the project the authored merge requests should be in.
               Incompatible with projectPath.
      DESC

    argument :include_archived, GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: "Merge requests from archived projects."

    attr_reader :project
    alias_method :user, :object

    def ready?(project_id: nil, project_path: nil, **args)
      return early_return unless can_read_profile?

      if project_id || project_path
        load_project(project_path, project_id)
        return early_return unless can_read_project?
      elsif args[:iids].present?
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'iids requires projectPath or projectId'
      end

      super(**args)
    end

    def resolve(**args)
      prepare_args(args)
      key = :"#{user_role}_id"
      super(key => user.id, **args)
    end

    def user_role
      raise NotImplementedError
    end

    private

    def can_read_profile?
      Ability.allowed?(current_user, :read_user_profile, user)
    end

    def can_read_project?
      Ability.allowed?(current_user, :read_merge_request, project)
    end

    def load_project(project_path, project_id)
      @project = ::Gitlab::Graphql::Lazy.force(resolve_project(full_path: project_path, project_id: project_id))
    end

    def no_results_possible?(args)
      some_argument_is_empty?(args)
    end

    # These arguments are handled in load_project, and should not be passed to
    # the finder directly.
    def prepare_args(args)
      args.delete(:project_id)
      args.delete(:project_path)
      args[:non_archived] = args.delete(:include_archived) != true
    end
  end
end
