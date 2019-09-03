# frozen_string_literal: true

module Releases
  class UpdateService < BaseService
    include Releases::Concerns

    def execute
      return error('Tag does not exist', 404) unless existing_tag
      return error('Release does not exist', 404) unless release
      return error('Access Denied', 403) unless allowed?
      return error('params is empty', 400) if empty_params?
      return error('Milestone does not exist', 400) if inexistent_milestone?

      params[:milestone] = milestone if param_for_milestone_title_provided?

      if release.update(params)
        success(tag: existing_tag, release: release)
      else
        error(release.errors.messages || '400 Bad request', 400)
      end
    end

    private

    def allowed?
      Ability.allowed?(current_user, :update_release, release)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def empty_params?
      params.except(:tag).empty?
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
