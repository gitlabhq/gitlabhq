# frozen_string_literal: true

xml.title   "#{@project.name} work items"
xml.link    href: url_for(safe_params), rel: "self", type: "application/atom+xml"
xml.link    href: project_work_items_url(@project), rel: "alternate", type: "text/html"
xml.id      project_work_items_url(@project)

if @work_items.any?
  xml.updated @work_items.first.updated_at.xmlschema
  xml << render(partial: 'work_items/work_item', collection: @work_items)
end
