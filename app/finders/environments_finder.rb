# frozen_string_literal: true

class EnvironmentsFinder
  attr_reader :project, :current_user, :params

  InvalidStatesError = Class.new(StandardError)

  def initialize(project, current_user, params = {})
    @project, @current_user, @params = project, current_user, params
  end

  # This method will eventually take the place of `#execute` as an
  # efficient way to get relevant environment entries.
  # Currently, `#execute` method has a serious technical debt and
  # we will likely rework on it in the future.
  # See more https://gitlab.com/gitlab-org/gitlab-foss/issues/63381
  def find
    environments = project.environments
    environments = by_name(environments)
    environments = by_search(environments)

    # Raises InvalidStatesError if params[:states] contains invalid states.
    environments = by_states(environments)

    environments
  end

  private

  def by_name(environments)
    if params[:name].present?
      environments.for_name(params[:name])
    else
      environments
    end
  end

  def by_search(environments)
    if params[:search].present?
      environments.for_name_like(params[:search], limit: nil)
    else
      environments
    end
  end

  def by_states(environments)
    if params[:states].present?
      environments_with_states(environments)
    else
      environments
    end
  end

  def environments_with_states(environments)
    # Convert to array of strings
    states = Array(params[:states]).map(&:to_s)

    raise InvalidStatesError, _('Requested states are invalid') unless valid_states?(states)

    environments.with_states(states)
  end

  def valid_states?(states)
    valid_states = Environment.valid_states.map(&:to_s)

    (states - valid_states).empty?
  end
end
