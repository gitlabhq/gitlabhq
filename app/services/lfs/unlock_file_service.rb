# frozen_string_literal: true

module Lfs
  class UnlockFileService < BaseService
    def execute
      unless can?(current_user, :push_code, project)
        raise Gitlab::GitAccess::ForbiddenError, _('You have no permissions')
      end

      unlock_file
    rescue Gitlab::GitAccess::ForbiddenError => ex
      error(ex.message, 403)
    rescue ActiveRecord::RecordNotFound
      error(_('Lock not found'), 404)
    rescue StandardError => ex
      error(ex.message, 500)
    end

    private

    def unlock_file
      forced = params[:force] == true

      if lock.can_be_unlocked_by?(current_user, forced)
        lock.destroy!

        project.refresh_lfs_file_locks_changed_epoch

        success(lock: lock, http_status: :ok)
      elsif forced
        error(_('You must have maintainer access to force delete a lock'), 403)
      else
        error(format(_("'%{lock_path}' is locked by @%{lock_user_name}"), lock_path: lock.path, lock_user_name: lock.user.username), 403)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def lock
      return @lock if defined?(@lock)

      @lock = if params[:id].present?
                project.lfs_file_locks.find(params[:id])
              elsif params[:path].present?
                project.lfs_file_locks.find_by!(path: params[:path])
              end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

Lfs::UnlockFileService.prepend_mod_with('Lfs::UnlockFileService')
