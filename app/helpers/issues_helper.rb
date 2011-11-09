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
end
