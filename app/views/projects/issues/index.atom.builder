# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord
xml.title   "#{@project.name} issues"
xml.link    href: url_for(safe_params.merge(only_path: false)), rel: "self", type: "application/atom+xml"
xml.link    href: project_issues_url(@project), rel: "alternate", type: "text/html"
xml.id      project_issues_url(@project)
xml.updated @issues.first.updated_at.xmlschema if @issues.reorder(nil).any?

xml << render(partial: 'issues/issue', collection: @issues) if @issues.reorder(nil).any?
# rubocop: enable CodeReuse/ActiveRecord
