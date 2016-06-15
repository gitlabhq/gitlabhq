xml.entry do
  xml.id      namespace_project_issue_url(issue.project.namespace, issue.project, issue)
  xml.link    href: namespace_project_issue_url(issue.project.namespace, issue.project, issue)
  xml.title   truncate(issue.title, length: 80)
  xml.updated issue.created_at.xmlschema
  xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon(issue.author_email))

  xml.author do
    xml.name issue.author_name
    xml.email issue.author_email
  end

  xml.summary issue.title
  xml.description issue.description if issue.description
  xml.milestone issue.milestone.title if issue.milestone
  xml.due_date issue.due_date if issue.due_date

  unless issue.labels.empty?
    xml.labels do
      issue.labels.each do |label|
        xml.label label.name
      end
    end
  end

  if issue.assignee
    xml.assignee do
      xml.name issue.assignee.name
      xml.email issue.assignee.email
    end
  end
end
