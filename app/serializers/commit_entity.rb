# frozen_string_literal: true

class CommitEntity < API::Entities::Commit
  include MarkupHelper
  include RequestAwareEntity

  expose :author, using: UserEntity

  expose :author_gravatar_url do |commit|
    GravatarService.new.execute(commit.author_email) # rubocop: disable CodeReuse/ServiceClass
  end

  expose :commit_url do |commit, options|
    project_commit_url(request.project, commit, params: options.fetch(:commit_url_params, {}))
  end

  expose :commit_path do |commit, options|
    project_commit_path(request.project, commit, params: options.fetch(:commit_url_params, {}))
  end

  expose :description_html, if: { type: :full } do |commit|
    markdown_field(commit, :description)
  end

  expose :title_html, if: { type: :full } do |commit|
    markdown_field(commit, :title)
  end

  expose :signature_html, if: { type: :full } do |commit|
    render('projects/commit/_signature', signature: commit.signature) if commit.has_signature?
  end

  def render(*args)
    return unless request.respond_to?(:render) && request.render.respond_to?(:call)

    request.render.call(*args)
  end
end
