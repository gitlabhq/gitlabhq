# frozen_string_literal: true

module Preloaders
  class GroupPolicyPreloader
    def initialize(groups, current_user)
      @groups = groups
      @current_user = current_user
    end

    def execute
      return if groups.blank?

      ActiveRecord::Associations::Preloader.new(
        records: groups,
        associations: [:organization]
      ).call

      Preloaders::UserMaxAccessLevelInGroupsPreloader.new(groups, current_user).execute
    end

    private

    attr_reader :groups, :current_user
  end
end

Preloaders::GroupPolicyPreloader.prepend_mod
