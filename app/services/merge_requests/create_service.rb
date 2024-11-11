# frozen_string_literal: true

module MergeRequests
  class CreateService < MergeRequests::BaseService
    def execute
      set_projects!
      set_default_attributes!

      merge_request = MergeRequest.new
      merge_request.target_project = @project
      merge_request.source_project = @source_project
      merge_request.source_branch = params[:source_branch]

      merge_after = params.delete(:merge_after)

      created_merge_request = create(merge_request)

      UpdateMergeScheduleService.new(created_merge_request, merge_after: merge_after).execute

      created_merge_request
    end

    def after_create(issuable)
      current_user_id = current_user.id

      issuable.run_after_commit do
        # Add new items to MergeRequests::AfterCreateService if they can
        # be performed in Sidekiq
        NewMergeRequestWorker.perform_async(issuable.id, current_user_id)
      end

      issuable.mark_as_preparing

      super
    end

    # expose issuable create method so it can be called from email
    # handler CreateMergeRequestHandler
    public :create

    private

    def before_create(merge_request)
      # If the fetching of the source branch occurs in an ActiveRecord
      # callback (e.g. after_create), a database transaction will be
      # open while the Gitaly RPC waits. To avoid an idle in transaction
      # timeout, we do this before we attempt to save the merge request.

      merge_request.skip_ensure_merge_request_diff = true
      merge_request.check_for_spam(user: current_user, action: :create)
    end

    def set_projects!
      # @project is used to determine whether the user can set the merge request's
      # assignee, milestone and labels. Whether they can depends on their
      # permissions on the target project.
      @source_project = @project
      @project = Project.find(params[:target_project_id]) if params[:target_project_id]

      # make sure that source/target project ids are not in
      # params so it can't be overridden later when updating attributes
      # from params when applying quick actions
      params.delete(:source_project_id)
      params.delete(:target_project_id)

      unless can?(current_user, :create_merge_request_from, @source_project) &&
          can?(current_user, :create_merge_request_in, @project)

        raise Gitlab::Access::AccessDeniedError
      end
    end

    def set_default_attributes!
      # Implemented in EE
    end
  end
end

MergeRequests::CreateService.prepend_mod_with('MergeRequests::CreateService')
