# frozen_string_literal: true

module Environments
  class EnvironmentsFinder
    attr_reader :project, :current_user, :params

    InvalidStatesError = Class.new(StandardError)

    def initialize(project, current_user, params = {})
      @project = project
      @current_user = current_user
      @params = params
    end

    def execute
      environments = project.environments
      environments = by_type(environments)
      environments = by_name(environments)
      environments = by_search(environments)
      environments = by_ids(environments)

      # Raises InvalidStatesError if params[:states] contains invalid states.
      by_states(environments)
    end

    private

    def by_type(environments)
      return environments unless params[:type].present?

      environments.for_type(params[:type])
    end

    def by_name(environments)
      if params[:name].present?
        environments.for_name(params[:name])
      else
        environments
      end
    end

    def by_search(environments)
      if params[:search].present?
        Environment.from_union(
          environments.for_name_like(params[:search], limit: nil),
          environments.for_name_like_within_folder(params[:search], limit: nil))
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

    def by_ids(environments)
      if params[:environment_ids].present?
        environments.id_in(params[:environment_ids])
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
end
