# frozen_string_literal: true

module Ci
  class RunnerPolicy < BasePolicy
    with_scope :subject
    condition(:locked) { @subject.locked? }

    condition(:can_admin_runner) do
      # Check global admin_runner permission for instance runners
      runner_owner = @subject.instance_type? ? :global : @subject.owner

      can?(:admin_runners, runner_owner)
    end

    with_score 20
    condition(:runner_available) do
      runner = @subject.is_a?(Ci::RunnerPresenter) ? @subject.__getobj__ : @subject

      # TODO: use User#ci_available_project_runners once the optimize_ci_owned_project_runners_query FF is removed
      # (https://gitlab.com/gitlab-org/gitlab/-/issues/551320)
      @user.ci_available_runners.include?(runner)
    end

    condition(:creator) do
      @user == @subject.creator
    end

    with_scope :subject
    condition(:is_instance_runner) do
      @subject.instance_type?
    end

    with_scope :subject
    condition(:is_group_runner) do
      @subject.group_type?
    end

    with_scope :subject
    condition(:is_project_runner) do
      @subject.project_type?
    end

    with_options scope: :user, score: 10
    condition(:any_maintainer_owned_groups_inheriting_shared_runners) do
      @user.owned_or_maintainers_groups.with_shared_runners_enabled.exists?
    end

    with_options scope: :user, score: 10
    condition(:any_maintainer_projects_inheriting_shared_runners) do
      @user.authorized_projects(Gitlab::Access::MAINTAINER).with_shared_runners_enabled.exists?
    end

    with_score 20
    condition(:any_associated_projects_in_group_runner_inheriting_group_runners) do
      # Check if any projects where user is a maintainer+ are inheriting group runners
      @subject.groups&.any? do |group|
        group.all_projects
             .with_group_runners_enabled
             .visible_to_user_and_access_level(@user, Gitlab::Access::MAINTAINER)
             .exists?
      end
    end

    with_score 20
    condition(:maintainer_in_any_associated_projects) do
      next true if maintainer_in_owner_scope?

      # Check if runner is associated to any projects where user is a maintainer+
      @subject.projects.visible_to_user_and_access_level(@user, Gitlab::Access::MAINTAINER).exists?
    end

    condition(:maintainer_in_owner_scope) do
      # Check if user is a maintainer+ in the scope owning the runner
      can?(:maintainer_access, @subject.owner)
    end

    with_score 20
    condition(:maintainer_in_any_associated_groups) do
      @subject.groups.any? do |group|
        can?(:maintainer_access, group)
      end
    end

    with_scope :subject
    condition(:belongs_to_multiple_projects) do
      @subject.belongs_to_more_than_one_project?
    end

    rule { anonymous }.prevent_all

    # NOTE: The `is_project_runner & belongs_to_multiple_projects & ` part is an optimization to avoid the
    # `runner_available` condition, which is much more expensive than the `can_admin_runner` one.
    # We can do this because:
    # - it doesn't handle instance runners.
    # - it handles group runners, but those only have a single group associated
    #   (and can be handled by the `can_admin_runner` rule).
    # - this leaves project runners. If they have a single associated project
    #   (the owner project, the can_admin_runner condition will be true).
    # So only if the runner has multiple projects is this rule useful at all.
    rule { is_project_runner & belongs_to_multiple_projects & runner_available }.policy do
      enable :read_builds
      enable :read_runner

      enable :assign_runner
      enable :update_runner
    end

    rule { admin | can_admin_runner }.policy do
      enable :read_builds
      enable :read_runner

      enable :assign_runner
      enable :update_runner
      enable :delete_runner
    end

    rule { is_instance_runner }.policy do
      # Any authenticated user can read instance runner information
      enable :read_runner
    end

    rule { is_group_runner & maintainer_in_any_associated_groups }.policy do
      enable :read_runner
    end

    rule { is_group_runner & any_associated_projects_in_group_runner_inheriting_group_runners }.policy do
      enable :read_runner
    end

    rule { is_project_runner & maintainer_in_any_associated_projects }.policy do
      enable :read_runner
    end

    rule { is_project_runner & maintainer_in_owner_scope }.policy do
      enable :update_runner
    end

    rule { can?(:read_runner) }.policy do
      enable :read_runner_sensitive_data
    end

    rule { creator }.enable :read_ephemeral_token

    rule { ~admin & belongs_to_multiple_projects }.prevent :delete_runner

    rule { ~admin & locked }.prevent :assign_runner

    rule { is_instance_runner & ~can_admin_runner }.prevent :read_runner_sensitive_data
  end
end

Ci::RunnerPolicy.prepend_mod_with('Ci::RunnerPolicy')
