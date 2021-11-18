# frozen_string_literal: true

module Preloaders
  class GroupPolicyPreloader
    def initialize(groups, current_user)
      @groups = groups
      @current_user = current_user
    end

    def execute
      Preloaders::UserMaxAccessLevelInGroupsPreloader.new(@groups, @current_user).execute
      Preloaders::GroupRootAncestorPreloader.new(@groups, root_ancestor_preloads).execute
    end

    private

    def root_ancestor_preloads
      []
    end
  end
end

Preloaders::GroupPolicyPreloader.prepend_mod_with('Preloaders::GroupPolicyPreloader')
