# frozen_string_literal: true

xml.title   "#{@group.name} work items"
xml.link    href: url_for(safe_params.merge(only_path: false)), rel: "self", type: "application/atom+xml"
xml.link    href: group_work_items_url, rel: "alternate", type: "text/html"
xml.id      group_work_items_url

if @work_items.any?
  xml.updated @work_items.first.updated_at.xmlschema
  xml << render(partial: 'work_items/work_item', collection: @work_items)
end
