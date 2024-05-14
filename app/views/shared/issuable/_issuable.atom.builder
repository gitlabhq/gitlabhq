# frozen_string_literal: true
builder.title   truncate(issuable.title, length: 160)
builder.updated issuable.updated_at.xmlschema
builder.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon_for_user(issuable.author))

builder.author do
  builder.name issuable.author_name
  builder.email issuable.author_public_email
end

builder.summary issuable.title
builder.description truncate(issuable.description, length: 240) if issuable.description
builder.content issuable.description if issuable.description
builder.milestone issuable.milestone.title if issuable.milestone

unless issuable.labels.empty?
  builder.labels do
    issuable.labels.each do |label|
      builder.label label.name
    end
  end
end

if issuable.assignees.any?
  builder.assignees do
    issuable.assignees.each do |assignee|
      builder.assignee do
        builder.name assignee.name
        builder.email assignee.public_email
      end
    end
  end

  builder.assignee do
    builder.name issuable.assignees.first.name
    builder.email issuable.assignees.first.public_email
  end
end
