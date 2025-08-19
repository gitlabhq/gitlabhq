# frozen_string_literal: true

xml.entry do
  xml.id      project_work_item_url(work_item.project, work_item)
  xml.link    href: project_work_item_url(work_item.project, work_item)
  # using the shovel operator (xml <<) would make us lose indentation, so we do this (https://github.com/rails/rails/issues/7036)
  render(partial: 'work_items/work_item_detail', object: work_item, locals: { builder: xml })
  xml.due_date work_item.due_date if work_item.due_date
end
