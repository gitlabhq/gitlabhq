# frozen_string_literal: true

xml.entry do
  work_item_url = Gitlab::Routing.url_helpers.polymorphic_url([
    work_item.namespace.owner_entity,
    work_item
  ])
  xml.id      work_item_url
  xml.link    href: work_item_url
  # using the shovel operator (xml <<) would make us lose indentation, so we do this (https://github.com/rails/)

  xml.id      work_item_url
  xml.link    href: work_item_url
  # using the shovel operator (xml <<) would make us lose indentation, so we do this (https://github.com/rails/rails/issues/7036)
  render(partial: 'work_items/work_item_detail', object: work_item, locals: { builder: xml })
  xml.due_date work_item.due_date if work_item.due_date
end
