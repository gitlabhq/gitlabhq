# frozen_string_literal: true

module Ci
  class RunnerPolicy < BasePolicy
    with_options scope: :subject, score: 0
    condition(:locked, scope: :subject) { @subject.locked? }

    with_options score: 20
    condition(:owned_runner) do
      @user.runner_available?(@subject)
    end

    condition(:creator) do
      @user == @subject.creator
    end

    with_options scope: :subject, score: 0
    condition(:is_instance_runner) do
      @subject.instance_type?
    end

    with_options scope: :subject, score: 0
    condition(:is_group_runner) do
      @subject.group_type?
    end

    with_options scope: :subject, score: 0
    condition(:is_project_runner) do
      @subject.project_type?
    end

    with_options scope: :user, score: 5
    condition(:any_maintainer_owned_groups_inheriting_shared_runners) do
      @user.owned_or_maintainers_groups.with_shared_runners_enabled.exists?
    end

    with_options scope: :user, score: 5
    condition(:any_maintainer_projects_inheriting_shared_runners) do
      @user.authorized_projects(Gitlab::Access::MAINTAINER).with_shared_runners_enabled.exists?
    end

    with_options score: 10
    condition(:any_associated_projects_in_group_runner_inheriting_group_runners) do
      # Check if any projects where user is a maintainer+ are inheriting group runners
      @subject.groups&.any? do |group|
        group.all_projects
             .with_group_runners_enabled
             .visible_to_user_and_access_level(@user, Gitlab::Access::MAINTAINER)
             .exists?
      end
    end

    with_options score: 6
    condition(:maintainer_in_any_associated_projects) do
      # Check if runner is associated to any projects where user is a maintainer+
      @subject.projects.visible_to_user_and_access_level(@user, Gitlab::Access::MAINTAINER).exists?
    end

    with_options score: 6
    condition(:maintainer_in_owner_project) do
      # Check if user is a maintainer+ in the project owning the runner
      @user.authorized_projects(Gitlab::Access::MAINTAINER).id_in(@subject.owner).exists?
    end

    with_score 6
    condition(:maintainer_in_any_associated_groups) do
      @subject.groups.any? do |group|
        can?(:maintainer_access, group)
      end
    end

    condition(:belongs_to_multiple_projects, scope: :subject) do
      @subject.belongs_to_more_than_one_project?
    end

    rule { anonymous }.prevent_all

    rule { admin | owned_runner }.policy do
      enable :read_builds

      enable :read_runner
      enable :assign_runner
      enable :update_runner
      enable :delete_runner
    end

    rule { is_instance_runner & any_maintainer_owned_groups_inheriting_shared_runners }.policy do
      enable :read_runner
    end

    rule { is_instance_runner & any_maintainer_projects_inheriting_shared_runners }.policy do
      enable :read_runner
    end

    rule { is_project_runner & maintainer_in_owner_project }.policy do
      enable :update_runner
    end

    rule { is_project_runner & maintainer_in_any_associated_projects }.policy do
      enable :read_runner
    end

    rule { is_group_runner & maintainer_in_any_associated_groups }.policy do
      enable :read_runner
    end

    rule { is_group_runner & any_associated_projects_in_group_runner_inheriting_group_runners }.policy do
      enable :read_runner
    end

    rule { ~admin & belongs_to_multiple_projects }.prevent :delete_runner

    rule { ~admin & locked }.prevent :assign_runner

    rule { creator }.enable :read_ephemeral_token
  end
end

Ci::RunnerPolicy.prepend_mod_with('Ci::RunnerPolicy')
