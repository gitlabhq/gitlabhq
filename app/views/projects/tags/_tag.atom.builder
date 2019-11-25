commit = @repository.commit(tag.dereferenced_target)
release = @releases.find { |r| r.tag == tag.name }
tag_url = project_tag_url(@project, tag.name)

if commit
  xml.entry do
    xml.id      tag_url
    xml.link    href: tag_url
    xml.title   truncate(tag.name, length: 80)
    xml.summary strip_signature(tag.message)
    xml.content markdown_field(release, :description), type: 'html'
    xml.updated release.updated_at.xmlschema if release
    xml.media   :thumbnail, width: '40', height: '40', url: image_url(avatar_icon_for_email(commit.author_email))
    xml.author do |author|
      xml.name  commit.author_name
      xml.email commit.author_email
    end
  end
end
