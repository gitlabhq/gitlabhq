# frozen_string_literal: true

module CommitsHelper
  # Returns a link to the commit author. If the author has a matching user and
  # is a member of the current @project it will link to the team member page.
  # Otherwise it will link to the author email as specified in the commit.
  #
  # options:
  #  avatar: true will prepend the avatar image
  #  size:   size of the avatar image in px
  def commit_author_link(commit, options = {})
    commit_person_link(commit, options.merge(source: :author))
  end

  # Just like #author_link but for the committer.
  def commit_committer_link(commit, options = {})
    commit_person_link(commit, options.merge(source: :committer))
  end

  def commit_to_html(commit, ref, project)
    render 'projects/commits/commit.html',
      commit: commit,
      ref: ref,
      project: project
  end

  # Breadcrumb links for a Project and, if applicable, a tree path
  def commits_breadcrumbs
    return unless @project && @ref

    # Add the root project link and the arrow icon
    crumbs = content_tag(:li, class: 'breadcrumb-item') do
      link_to(
        @project.path,
        project_commits_path(@project, @ref)
      )
    end

    if @path
      parts = @path.split('/')

      parts.each_with_index do |part, i|
        crumbs << content_tag(:li, class: 'breadcrumb-item') do
          # The text is just the individual part, but the link needs all the parts before it
          link_to(
            part,
            project_commits_path(
              @project,
              tree_join(@ref, parts[0..i].join('/'))
            )
          )
        end
      end
    end

    crumbs.html_safe
  end

  # Return Project default branch, if it present in array
  # Else - first branch in array (mb last actual branch)
  def commit_default_branch(project, branches)
    branches.include?(project.default_branch) ? branches.delete(project.default_branch) : branches.pop
  end

  # Returns a link formatted as a commit branch link
  def commit_branch_link(url, text)
    link_to(url, class: 'badge badge-gray ref-name branch-link') do
      sprite_icon('branch', size: 12, css_class: 'fork-svg') + "#{text}"
    end
  end

  # Returns the sorted alphabetically links to branches, separated by a comma
  def commit_branches_links(project, branches)
    branches.sort.map do |branch|
      commit_branch_link(project_ref_path(project, branch), branch)
    end.join(' ').html_safe
  end

  # Returns a link formatted as a commit tag link
  def commit_tag_link(url, text)
    link_to(url, class: 'badge badge-gray ref-name') do
      sprite_icon('tag', size: 12, css_class: 'gl-mr-2 vertical-align-middle') + "#{text}"
    end
  end

  # Returns the sorted links to tags, separated by a comma
  def commit_tags_links(project, tags)
    sorted = VersionSorter.rsort(tags)
    sorted.map do |tag|
      commit_tag_link(project_ref_path(project, tag), tag)
    end.join(' ').html_safe
  end

  def link_to_browse_code(project, commit)
    return unless current_controller?(:commits)

    if @path.blank?
      url = project_tree_path(project, commit)
      tooltip = _("Browse Files")
    elsif @repo.blob_at(commit.id, @path)
      url = project_blob_path(project, tree_join(commit.id, @path))
      tooltip = _("Browse File")
    elsif @path.present?
      url = project_tree_path(project, tree_join(commit.id, @path))
      tooltip = _("Browse Directory")
    end

    link_to url, class: "btn gl-button btn-default btn-icon has-tooltip", title: tooltip, data: { container: "body" } do
      sprite_icon('folder-open')
    end
  end

  def commit_options_dropdown_data(project, commit)
    can_collaborate = current_user && can_collaborate_with_project?(project)

    {
      new_project_tag_path: new_project_tag_path(project, ref: commit),
      email_patches_path: project_commit_path(project, commit, format: :patch),
      plain_diff_path: project_commit_path(project, commit, format: :diff),
      can_revert: "#{can_collaborate && !commit.has_been_reverted?(current_user)}",
      can_cherry_pick: can_collaborate.to_s,
      can_tag: can?(current_user, :push_code, project).to_s,
      can_email_patches: (commit.parents.length < 2).to_s
    }
  end

  def commit_signature_badge_classes(additional_classes)
    %w(btn gpg-status-box) + Array(additional_classes)
  end

  def conditionally_paginate_diff_files(diffs, paginate:, per:)
    if paginate
      Kaminari.paginate_array(diffs.diff_files.to_a).page(params[:page]).per(per)
    else
      diffs.diff_files
    end
  end

  def cherry_pick_projects_data(project)
    [project, project.forked_from_project].compact.map do |project|
      {
        id: project.id.to_s,
        name: project.full_path,
        refsUrl: refs_project_path(project)
      }
    end
  end

  # This is used to calculate a cache key for the app/views/projects/commits/_commit.html.haml
  # partial. It takes some of the same parameters as used in the partial and will hash the
  # current pipeline status.
  #
  # This includes a keyed hash for values that can be nil, to prevent invalid cache entries
  # being served if the order should change in future.
  def commit_partial_cache_key(commit, ref:, merge_request:, request:)
    [
      commit,
      commit.author,
      ref,
      {
        merge_request: merge_request&.cache_key,
        pipeline_status: commit.status_for(ref)&.cache_key,
        xhr: request.xhr?,
        controller: controller.controller_path,
        path: @path # referred to in #link_to_browse_code
      }
    ]
  end

  DEFAULT_SHA = '0000000'

  # Returns the template path for commit resources
  # to be utilized by the client applications.
  def commit_path_template(project)
    project_commit_path(project, DEFAULT_SHA).sub("/#{DEFAULT_SHA}", '/$COMMIT_SHA')
  end

  protected

  # Private: Returns a link to a person. If the person has a matching user and
  # is a member of the current @project it will link to the team member page.
  # Otherwise it will link to the person email as specified in the commit.
  #
  # options:
  #  source: one of :author or :committer
  #  avatar: true will prepend the avatar image
  #  size:   size of the avatar image in px
  def commit_person_link(commit, options = {})
    user = commit.public_send(options[:source]) # rubocop:disable GitlabSecurity/PublicSend

    source_name = clean(commit.public_send(:"#{options[:source]}_name")) # rubocop:disable GitlabSecurity/PublicSend
    source_email = clean(commit.public_send(:"#{options[:source]}_email")) # rubocop:disable GitlabSecurity/PublicSend

    person_name = user.try(:name) || source_name

    text =
      if options[:avatar]
        content_tag(:span, person_name, class: "commit-#{options[:source]}-name")
      else
        person_name
      end

    link_options = {
      class: "commit-#{options[:source]}-link"
    }

    if user.nil?
      mail_to(source_email, text, link_options)
    else
      link_to(text, user_path(user), { class: "commit-#{options[:source]}-link js-user-link", data: { user_id: user.id } })
    end
  end

  def view_file_button(commit_sha, diff_new_path, project, replaced: false)
    path = project_blob_path(project, tree_join(commit_sha, diff_new_path))
    title = replaced ? _('View replaced file @ ') : _('View file @ ')

    link_to(path, class: 'btn gl-button btn-default') do
      raw(title) + content_tag(:span, truncate_sha(commit_sha), class: 'commit-sha')
    end
  end

  def view_on_environment_button(commit_sha, diff_new_path, environment)
    return unless environment && commit_sha

    external_url = environment.external_url_for(diff_new_path, commit_sha)
    return unless external_url

    link_to(external_url, class: 'btn gl-button btn-default btn-file-option has-tooltip', target: '_blank', rel: 'noopener noreferrer', title: "View on #{environment.formatted_external_url}", data: { container: 'body' }) do
      sprite_icon('external-link')
    end
  end

  def truncate_sha(sha)
    Commit.truncate_sha(sha)
  end

  def clean(string)
    Sanitize.clean(string, remove_contents: true)
  end

  def commit_path(project, commit, merge_request: nil)
    if merge_request&.persisted?
      diffs_project_merge_request_path(project, merge_request, commit_id: commit.id)
    elsif merge_request
      project_commit_path(merge_request&.source_project, commit)
    else
      project_commit_path(project, commit)
    end
  end
end
