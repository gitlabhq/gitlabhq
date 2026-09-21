# frozen_string_literal: true

if @gitaly_unavailable
  # rubocop:disable Cop/StaticTranslationDefinition -- Builder files are executed dynamically
  xml.title s_('Commits|Unable to load commits')
  # rubocop:enable Cop/StaticTranslationDefinition
  #
  # Gitaly may fail before or after assign_ref_vars is executed so we check if
  # @ref is blank before attempting to generate the commits url as a blank ref
  # will raise UrlGenerationError. If ref is blank we fallback to the project's
  # url instead.
  resource_url = @ref.blank? ? project_url(@project) : project_commits_url(@project, @ref)
  xml.link    href: resource_url, rel: "alternate", type: "text/html"
  xml.id      resource_url
else
  xml.title   "#{@project.name}:#{@ref} commits"
  xml.link    href: project_commits_url(@project, @ref, rss_url_options), rel: "self", type: "application/atom+xml"
  xml.link    href: project_commits_url(@project, @ref), rel: "alternate", type: "text/html"
  xml.id      project_commits_url(@project, @ref)
  xml.updated @commits.first.committed_date.xmlschema if @commits.any?

  xml << render(@commits) if @commits.any?
end
