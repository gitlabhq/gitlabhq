# frozen_string_literal: true

xml.title   "#{@group.name} merge requests"
xml.link    href: url_for(safe_params.merge(only_path: false)), rel: "self", type: "application/atom+xml"
xml.link    href: merge_requests_group_url, rel: "alternate", type: "text/html"
xml.id      merge_requests_group_url

first_merge_request = @merge_requests.reorder(nil).first # rubocop:disable CodeReuse/ActiveRecord -- Needed for performance checks before rendering collection

if first_merge_request
  xml.updated first_merge_request.updated_at.xmlschema
  xml << render(partial: 'projects/merge_requests/merge_request',
    collection: @merge_requests)
end
