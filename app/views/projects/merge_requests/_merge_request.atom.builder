# frozen_string_literal: true

xml.entry do
  xml.id      project_merge_request_url(merge_request.project, merge_request)
  xml.link    href: project_merge_request_url(merge_request.project, merge_request)
  # using the shovel operator (xml <<) would make us lose indentation, so we do this (https://github.com/rails/rails/issues/7036)
  render(partial: 'shared/issuable/issuable', object: merge_request, locals: { builder: xml })
end
