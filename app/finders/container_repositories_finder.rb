# frozen_string_literal: true

class ContainerRepositoriesFinder
  VALID_SUBJECTS = [Group, Project].freeze

  def initialize(user:, subject:)
    @user = user
    @subject = subject
  end

  def execute
    raise ArgumentError, "invalid subject_type" unless valid_subject_type?
    return unless authorized?

    return project_repositories if @subject.is_a?(Project)
    return group_repositories if @subject.is_a?(Group)
  end

  private

  def valid_subject_type?
    VALID_SUBJECTS.include?(@subject.class)
  end

  def project_repositories
    return unless @subject.container_registry_enabled

    @subject.container_repositories
  end

  def group_repositories
    ContainerRepository.for_group_and_its_subgroups(@subject)
  end

  def authorized?
    Ability.allowed?(@user, :read_container_image, @subject)
  end
end
