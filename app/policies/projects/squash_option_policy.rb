# frozen_string_literal: true

module Projects
  class SquashOptionPolicy < ::BasePolicy
    delegate { @subject.branch_rule }

    rule { can?(:read_branch_rule) }.policy do
      enable :read_squash_option
    end

    rule { can?(:update_branch_rule) }.policy do
      enable :create_squash_option
      enable :update_squash_option
      enable :destroy_squash_option
    end
  end
end
