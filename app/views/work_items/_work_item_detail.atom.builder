# frozen_string_literal: true

builder.title   truncate(work_item_detail.title, length: 160)
builder.updated work_item_detail.updated_at.xmlschema
builder.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon_for_user(work_item_detail.author))

builder.author do
  builder.name work_item_detail.author_name
  builder.email work_item_detail.author_public_email
end

builder.summary work_item_detail.title
builder.description truncate(work_item_detail.description, length: 240) if work_item_detail.description
builder.content work_item_detail.description if work_item_detail.description
builder.milestone work_item_detail.milestone.title if work_item_detail.milestone

# Work item specific fields
builder.work_item_type work_item_detail.work_item_type.name if work_item_detail.work_item_type
builder.state work_item_detail.state

unless work_item_detail.labels.empty?
  builder.labels do
    work_item_detail.labels.each do |label|
      builder.label label.name
    end
  end
end

if work_item_detail.assignees.any?
  builder.assignees do
    work_item_detail.assignees.each do |assignee|
      builder.assignee do
        builder.name assignee.name
        builder.email assignee.public_email
      end
    end
  end

  builder.assignee do
    builder.name work_item_detail.assignees.first.name
    builder.email work_item_detail.assignees.first.public_email
  end
end
