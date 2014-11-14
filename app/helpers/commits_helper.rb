# encoding: utf-8
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

  def image_diff_class(diff)
    if diff.deleted_file
      "deleted"
    elsif diff.new_file
      "added"
    else
      nil
    end
  end

  def commit_to_html(commit, project, inline = true)
    template = inline ? "inline_commit" : "commit"
    escape_javascript(render "projects/commits/#{template}", commit: commit, project: project) unless commit.nil?
  end

  # Breadcrumb links for a Project and, if applicable, a tree path
  def commits_breadcrumbs
    return unless @project && @ref

    # Add the root project link and the arrow icon
    crumbs = content_tag(:li) do
      link_to(@project.path, project_commits_path(@project, @ref))
    end

    if @path
      parts = @path.split('/')

      parts.each_with_index do |part, i|
        crumbs += content_tag(:li) do
          # The text is just the individual part, but the link needs all the parts before it
          link_to part, project_commits_path(@project, tree_join(@ref, parts[0..i].join('/')))
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

  # Returns the sorted alphabetically links to branches, separated by a comma
  def commit_branches_links(project, branches)
    branches.sort.map { |branch| link_to(branch, project_tree_path(project, branch)) }.join(", ").html_safe
  end

  def link_to_browse_code(project, commit)
    if current_controller?(:projects, :commits)
      if @repo.blob_at(commit.id, @path)
        return link_to "Browse File »", project_blob_path(project, tree_join(commit.id, @path)), class: "pull-right"
      elsif @path.present?
        return link_to "Browse Dir »", project_tree_path(project, tree_join(commit.id, @path)), class: "pull-right"
      end
    end
    link_to "Browse Code »", project_tree_path(project, commit), class: "pull-right"
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
    source_name = clean(commit.send "#{options[:source]}_name".to_sym)
    source_email = clean(commit.send "#{options[:source]}_email".to_sym)

    user = User.find_for_commit(source_email, source_name)
    person_name = user.nil? ? source_name : user.name
    person_email = user.nil? ? source_email : user.email

    text = if options[:avatar]
            avatar = image_tag(avatar_icon(person_email, options[:size]), class: "avatar #{"s#{options[:size]}" if options[:size]}", width: options[:size], alt: "")
            %Q{#{avatar} <span class="commit-#{options[:source]}-name">#{person_name}</span>}
          else
            person_name
          end

    options = {
      class: "commit-#{options[:source]}-link has_tooltip",
      data: { :'original-title' => sanitize(source_email) }
    }

    if user.nil?
      mail_to(source_email, text.html_safe, options)
    else
      link_to(text.html_safe, user_path(user), options)
    end
  end

  def view_file_btn(commit_sha, diff, project)
    link_to project_blob_path(project, tree_join(commit_sha, diff.new_path)),
            class: 'btn btn-small view-file js-view-file' do
      raw('View file @') + content_tag(:span, commit_sha[0..6],
                                       class: 'commit-short-id')
    end
  end

  def truncate_sha(sha)
    Commit.truncate_sha(sha)
  end

  def clean(string)
    Sanitize.clean(string, remove_contents: true)
  end
end
