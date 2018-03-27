xml.entry do
  xml.id      project_issue_url(issue.project, issue)
  xml.link    href: project_issue_url(issue.project, issue)
  xml.title   truncate(issue.title, length: 80)
  xml.updated issue.updated_at.xmlschema
  xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon_for_user(issue.author))

  xml.author do
    xml.name issue.author_name
    xml.email issue.author_public_email
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

  if issue.assignees.any?
    xml.assignees do
      issue.assignees.each do |assignee|
        xml.assignee do
          xml.name assignee.name
          xml.email assignee.public_email
        end
      end
    end

    xml.assignee do
      xml.name issue.assignees.first.name
      xml.email issue.assignees.first.public_email
    end
  end
end
