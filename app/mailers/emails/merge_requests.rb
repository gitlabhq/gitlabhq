module Emails
  module MergeRequests
    def new_merge_request_email(recipient_id, merge_request_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      @target_url = project_merge_request_url(@project, @merge_request)
      mail_new_thread(@merge_request,
                      from: sender(@merge_request.author_id),
                      to: recipient(recipient_id),
                      subject: subject("#{@merge_request.title} (##{@merge_request.iid})"))
    end

    def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id, updated_by_user_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id
      @project = @merge_request.project
      @target_url = project_merge_request_url(@project, @merge_request)
      mail_answer_thread(@merge_request,
                         from: sender(updated_by_user_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@merge_request.title} (##{@merge_request.iid})"))
    end

    def closed_merge_request_email(recipient_id, merge_request_id, updated_by_user_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @updated_by = User.find updated_by_user_id
      @project = @merge_request.project
      @target_url = project_merge_request_url(@project, @merge_request)
      mail_answer_thread(@merge_request,
                         from: sender(updated_by_user_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@merge_request.title} (##{@merge_request.iid})"))
    end

    def merged_merge_request_email(recipient_id, merge_request_id, updated_by_user_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      @target_url = project_merge_request_url(@project, @merge_request)
      mail_answer_thread(@merge_request,
                         from: sender(updated_by_user_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@merge_request.title} (##{@merge_request.iid})"))
    end

    def merge_request_status_email(recipient_id, merge_request_id, status, updated_by_user_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @mr_status = status
      @project = @merge_request.project
      @updated_by = User.find updated_by_user_id
      @target_url = project_merge_request_url(@project, @merge_request)
      set_reference("merge_request_#{merge_request_id}")
      mail(from: sender(updated_by_user_id),
           to: recipient(recipient_id),
           subject: subject("#{@merge_request.title} (##{@merge_request.iid}) #{@mr_status}"))
    end
  end

  # Over rides default behavour to show source/target
  # Formats arguments into a String suitable for use as an email subject
  #
  # extra - Extra Strings to be inserted into the subject
  #
  # Examples
  #
  #   >> subject('Lorem ipsum')
  #   => "GitLab Merge Request | Lorem ipsum"
  #
  #   # Automatically inserts Project name:
  #   Forked MR
  #   => source project => <Project id: 1, name: "Ruby on Rails", path: "ruby_on_rails", ...>
  #   => target project => <Project id: 2, name: "My Ror", path: "ruby_on_rails", ...>
  #   => source branch => source
  #   => target branch => target
  #   >> subject('Lorem ipsum')
  #   => "GitLab Merge Request | Ruby on Rails:source >> My Ror:target | Lorem ipsum "
  #
  #   Non Forked MR
  #   => source project => <Project id: 1, name: "Ruby on Rails", path: "ruby_on_rails", ...>
  #   => target project => <Project id: 1, name: "Ruby on Rails", path: "ruby_on_rails", ...>
  #   => source branch => source
  #   => target branch => target
  #   >> subject('Lorem ipsum')
  #   => "GitLab Merge Request | Ruby on Rails | source >> target | Lorem ipsum "
  #   # Accepts multiple arguments
  #   >> subject('Lorem ipsum', 'Dolor sit amet')
  #   => "GitLab Merge Request | Lorem ipsum | Dolor sit amet"
  def subject(*extra)
    subject = "Merge Request | "
    if @merge_request.for_fork?
      subject << "#{@merge_request.source_project.name_with_namespace}:#{merge_request.source_branch} >> #{@merge_request.target_project.name_with_namespace}:#{merge_request.target_branch}"
    else
      subject << "#{@merge_request.source_project.name_with_namespace} | #{merge_request.source_branch} >> #{merge_request.target_branch}"
    end
    subject << " | " + extra.join(' | ') if extra.present?
    subject
  end

end
