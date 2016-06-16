xml.entry do
  xml.id      namespace_project_issue_url(issue.project.namespace, issue.project, issue)
  xml.link    href: namespace_project_issue_url(issue.project.namespace, issue.project, issue)
  xml.title   truncate(issue.title, length: 80)
  xml.updated issue.created_at.xmlschema
  xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon(issue.author_email))

  xml.author do |author|
    xml.name issue.author_name
    xml.email issue.author_email
  end

  xml.summary issue.title
end
