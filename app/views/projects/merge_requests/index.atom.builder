# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord
xml.title   "#{@project.name} merge requests"
xml.link    href: url_for(safe_params), rel: "self", type: "application/atom+xml"
xml.link    href: project_merge_requests_url(@project), rel: "alternate", type: "text/html"
xml.id      project_merge_requests_url(@project)
xml.updated @merge_requests.first.updated_at.xmlschema if @merge_requests.reorder(nil).any?

xml << render(partial: 'projects/merge_requests/merge_request', collection: @merge_requests) if @merge_requests.reorder(nil).any?
# rubocop: enable CodeReuse/ActiveRecord
