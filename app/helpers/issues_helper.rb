module IssuesHelper
  def sort_class
    if can?(current_user, :admin_issue, @project) && (!params[:f] || params[:f] == "0")
                        "handle"
    end
  end

  def project_issues_filter_path project, params = {}
    params[:f] ||= cookies['issue_filter']
    project_issues_path project, params
  end

  def project_issues_change_status issue, is_being_closed
    note = Note.new(:noteable => issue, :project => @project)
    note.author = current_user
    note.note = "_Status changed to #{is_being_closed ? 'closed' : 'reopened'}_"
    note.save()
  end
end
