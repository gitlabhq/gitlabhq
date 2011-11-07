module IssuesHelper
  def sort_class
    if can?(current_user, :admin_issue, @project) && (!params[:f] || params[:f] == "0")
      "handle"
    end
  end
end
