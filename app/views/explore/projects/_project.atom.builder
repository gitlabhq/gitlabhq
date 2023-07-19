# frozen_string_literal: true

xml.entry do
  xml.title   project.name
  xml.link    href: project_url(project), rel: "alternate", type: "text/html"
  xml.id      project_url(project)
  xml.updated project.created_at

  if project.description.present?
    xml.summary(type: "xhtml") do |summary|
      summary << project.description
    end
  end
end
