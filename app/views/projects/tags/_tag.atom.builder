# frozen_string_literal: true

commit = @repository.commit(tag.dereferenced_target)
release = @releases.find { |r| r.tag == tag.name }
tag_url = project_tag_url(@project, tag.name)
author_email = Gitlab::SafeRequestStore.fetch([:commit_author_email, commit.author_email]) do
  commit.author&.public_email || commit.author_email
end

if commit
  xml.entry do
    xml.id      tag_url
    xml.link    href: tag_url
    xml.title   truncate(tag.name, length: 160)
    xml.summary strip_signature(tag.message)
    xml.content markdown_field(release, :description), type: 'html'
    xml.updated commit.committed_date.xmlschema
    xml.media   :thumbnail, width: '40', height: '40', url: image_url(avatar_icon_for_email(author_email))
    xml.author do |author|
      xml.name  commit.author_name
      xml.email author_email
    end
  end
end
