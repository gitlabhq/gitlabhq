# frozen_string_literal: true

xml.entry do
  xml.id      project_issue_url(issue.project, issue)
  xml.link    href: project_issue_url(issue.project, issue)
  # using the shovel operator (xml <<) would make us lose indentation, so we do this (https://github.com/rails/rails/issues/7036)
  render(partial: 'shared/issuable/issuable', object: issue, locals: { builder: xml })
  xml.due_date issue.due_date if issue.due_date
end
