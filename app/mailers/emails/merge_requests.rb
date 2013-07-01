module Emails
  module MergeRequests
    def new_merge_request_email(recipient_id, merge_request_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      mail(to: recipient(recipient_id), subject: subject("new merge request !#{@merge_request.id}", @merge_request.title))
    end

    def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @previous_assignee = User.find_by_id(previous_assignee_id) if previous_assignee_id
      @project = @merge_request.project
      mail(to: recipient(recipient_id), subject: subject("changed merge request !#{@merge_request.id}", @merge_request.title))
    end

    def closed_merge_request_email(recipient_id, merge_request_id, updated_by_user_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      @updated_by = User.find updated_by_user_id
      mail(to: recipient(recipient_id), subject: subject("Closed merge request !#{@merge_request.id}", @merge_request.title))
    end

    def merged_merge_request_email(recipient_id, merge_request_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      mail(to: recipient(recipient_id), subject: subject("Accepted merge request !#{@merge_request.id}", @merge_request.title))
    end
  end
end
