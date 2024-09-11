# frozen_string_literal: true

release_url = project_release_url(@project, tag: release.tag)
author_email = Gitlab::SafeRequestStore.fetch([:release_author_email, release.author.email]) do
  release.author&.public_email || release.author&.email
end

xml.entry do
  xml.id        release_url
  xml.link      href: release_url
  xml.title     truncate(release.name, length: 160)
  xml.summary   strip_signature(release.commit.message) if can?(current_user, :read_code, @project)
  xml.content   markdown_field(release, :description), type: 'html'
  xml.updated   release.updated_at.xmlschema
  xml.published release.released_at.xmlschema
  xml.author do
    xml.name  release.author&.name
    xml.email author_email
  end
end
