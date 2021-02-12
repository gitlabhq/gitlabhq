# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord
xml.title   "#{@group.name} issues"
xml.link    href: url_for(safe_params), rel: "self", type: "application/atom+xml"
xml.link    href: issues_group_url, rel: "alternate", type: "text/html"
xml.id      issues_group_url
xml.updated @issues.first.updated_at.xmlschema if @issues.reorder(nil).any?

xml << render(partial: 'issues/issue', collection: @issues) if @issues.reorder(nil).any?
# rubocop: enable CodeReuse/ActiveRecord
