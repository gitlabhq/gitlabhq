module Emails
  module MergeRequests
    def new_merge_request_email(merge_request_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      mail(to: @merge_request.assignee_email, subject: subject("new merge request !#{@merge_request.id}", @merge_request.title))
    end

    def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @previous_assignee ||= User.find(previous_assignee_id)
      @project = @merge_request.project
      mail(to: recipient(recipient_id), subject: subject("changed merge request !#{@merge_request.id}", @merge_request.title))
    end
  end
end
