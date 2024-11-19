# frozen_string_literal: true

module Releases
  class UpdateService < Releases::BaseService
    def execute
      if error = validate
        return error
      end

      if param_for_milestones_provided?
        previous_milestones = release.milestones.map(&:id)
        params[:milestones] = milestones
      end

      # transaction needed as Rails applies `save!` to milestone_releases
      # when it does assign_attributes instead of actual saving
      # this leads to the validation error being raised
      # see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43385
      ApplicationRecord.transaction do
        if release.update(params)
          execute_hooks(release, 'update')
          audit(release, action: :updated)
          audit(release, action: :milestones_updated) if milestones_updated?(previous_milestones)
          success(tag: existing_tag, release: release, milestones_updated: milestones_updated?(previous_milestones))
        else
          error(release.errors.messages || '400 Bad request', 400)
        end
      rescue ActiveRecord::RecordInvalid => e
        error(e.message || '400 Bad request', 400)
      end
    end

    private

    def validate
      return error(_('Tag does not exist'), 404) unless existing_tag
      return error(_('Release does not exist'), 404) unless release
      return error(_('Access Denied'), 403) unless allowed?
      return error(_('params is empty'), 400) if empty_params?

      if inexistent_milestone_titles.any?
        return error(
          format(_("Milestone(s) not found: %{milestones}"),
            milestones: inexistent_milestone_titles.join(', ')), 400)
      end

      return unless inexistent_milestone_ids.any?

      return error(
        format(_("Milestone id(s) not found: %{milestones}"),
          milestones: inexistent_milestone_ids.join(', ')), 400)
    end

    def allowed?
      Ability.allowed?(current_user, :update_release, release)
    end

    def empty_params?
      params.except(:tag).empty?
    end

    def milestones_updated?(previous_milestones)
      return false unless param_for_milestones_provided?

      previous_milestones.to_set != release.milestones.map(&:id)
    end
  end
end
