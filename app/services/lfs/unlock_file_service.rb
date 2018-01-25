module Lfs
  class UnlockFileService < BaseService
    prepend EE::Lfs::UnlockFileService

    def execute
      @lock = project.lfs_file_locks.find_by(id: params[:id])

      return error('Lock not found', 404) unless @lock

      unlock_file
    rescue => ex
      error(ex.message, 500)
    end

    private

    def unlock_file
      forced = params[:force] == true

      if @lock.can_be_unlocked_by?(current_user, forced)
        @lock.destroy!

        success(lock: @lock, http_status: :ok)
      elsif forced
        error('You must have master access to force delete a lock', 403)
      else
        error("#{@lock.path} is locked by GitLab User #{@lock.user_id}", 403)
      end
    end
  end
end
