# frozen_string_literal: true

module Groups
  class NestedCreateService < Groups::BaseService
    attr_reader :group_path, :visibility_level

    def initialize(user, params)
      @current_user = user
      @params = params.dup
      @group_path = @params.delete(:group_path)
      @visibility_level = @params.delete(:visibility_level) ||
        Gitlab::CurrentSettings.current_application_settings.default_group_visibility
    end

    def execute
      return unless group_path

      if namespace = namespace_or_group(group_path)
        return namespace
      end

      create_group_path
    end

    private

    def create_group_path
      group_path_segments = group_path.split('/')

      last_group = nil
      partial_path_segments = []
      while subgroup_name = group_path_segments.shift
        partial_path_segments << subgroup_name
        partial_path = partial_path_segments.join('/')

        new_params = params.reverse_merge(
          path: subgroup_name,
          name: subgroup_name,
          parent: last_group,
          visibility_level: visibility_level
        )

        last_group = namespace_or_group(partial_path) ||
          Groups::CreateService.new(current_user, new_params).execute
      end

      last_group
    end

    def namespace_or_group(group_path)
      Namespace.find_by_full_path(group_path)
    end
  end
end
