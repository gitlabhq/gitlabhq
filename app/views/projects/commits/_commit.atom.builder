# frozen_string_literal: true

xml.entry do
  xml.id      project_commit_url(@project, id: commit.id)
  xml.link    href: project_commit_url(@project, id: commit.id)
  xml.title   truncate(commit.title, length: 80, escape: false)
  xml.updated commit.committed_date.xmlschema
  xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon_for_email(commit.author_email))

  xml.author do |author|
    xml.name commit.author_name
    xml.email commit.author_email
  end

  xml.summary markdown_field(commit, :description), type: 'html'
end
