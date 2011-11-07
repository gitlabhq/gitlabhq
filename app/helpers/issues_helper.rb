module IssuesHelper
	def project_issues_filter_path project, params = {}
		params[:f] ||= cookies['issue_filter']
		project_issues_path project, params
	end
end
