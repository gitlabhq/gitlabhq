class UserProjectAccessChangedService
  def initialize(user_ids)
    @user_ids = Array.wrap(user_ids)
  end

  def execute
    AuthorizedProjectsWorker.bulk_perform_async(@user_ids.map { |id| [id] })
  end
end
