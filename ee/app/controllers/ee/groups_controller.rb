module EE
  module GroupsController
    extend ActiveSupport::Concern

    def group_params_attributes
      super + group_params_ee
    end

    private

    def group_params_ee
      [
        :membership_lock,
        :repository_size_limit
      ].tap do |params_ee|
        params_ee << :project_creation_level if current_group&.feature_available?(:project_creation_level)
      end
    end

    def current_group
      @group
    end
  end
end
