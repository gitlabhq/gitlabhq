# frozen_string_literal: true

class ContainerRepositoriesFinder
  VALID_SUBJECTS = [Group, Project].freeze

  def initialize(user:, subject:, params: {})
    @user = user
    @subject = subject
    @params = params
  end

  def execute
    raise ArgumentError, "invalid subject_type" unless valid_subject_type?
    return unless authorized?

    repositories = @subject.is_a?(Project) ? project_repositories : group_repositories
    repositories = filter_by_image_name(repositories)
    sort(repositories)
  end

  private

  def valid_subject_type?
    VALID_SUBJECTS.include?(@subject.class)
  end

  def project_repositories
    @subject.container_repositories
  end

  def group_repositories
    ContainerRepository.for_group_and_its_subgroups(@subject)
  end

  def filter_by_image_name(repositories)
    return repositories unless @params[:name]

    repositories.search_by_name(@params[:name])
  end

  def sort(repositories)
    return repositories unless @params[:sort]

    repositories.order_by(@params[:sort])
  end

  def authorized?
    Ability.allowed?(@user, :read_container_image, @subject)
  end
end
