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

  def each_diff_line(diff, index)
    Gitlab::DiffParser.new(diff.diff.lines.to_a, diff.new_path)
      .each do |full_line, type, line_code, line_new, line_old|
        yield(full_line, type, line_code, line_new, line_old)
      end
  end

  def parallel_diff_line(diff, index)
    Gitlab::DiffParser.new(diff.diff.lines.to_a, diff.new_path)
      .each do |full_line, type, line_code, line_new, line_old, raw_line, next_type, next_line|
        yield(full_line, type, line_code, line_new, line_old, raw_line, next_type, next_line)
      end
  end

  def parallel_diff(diff, index)
    lines = []
    skip_next = false

    # Building array of lines
    #
    # [left_type, left_line_number, left_line_content, right_line_type, right_line_number, right_line_content]
    #
    parallel_diff_line(diff, index) do |full_line, type, line_code, line_new, line_old, raw_line, next_type, next_line|
      line = [type, line_old, full_line, next_type, line_new]
      if type == 'match' || type.nil?
        # line in the right panel is the same as in the left one
        line = [type, line_old, full_line, type, line_new, full_line]
        lines.push(line)
      elsif type == 'old'
        if next_type == 'new'
          # Left side has text removed, right side has text added
          line.push(next_line)
          lines.push(line)
          skip_next = true
        elsif next_type == 'old' || next_type.nil?
          # Left side has text removed, right side doesn't have any change
          line.pop # remove the newline
          line.push(nil) # no line number on the right panel
          line.push("&nbsp;") # empty line on the right panel
          lines.push(line)
        end
      elsif type == 'new'
        if skip_next
          # Change has been already included in previous line so no need to do it again
          skip_next = false
          next
        else
          # Change is only on the right side, left side has no change
          line = [nil, nil, "&nbsp;", type, line_new, full_line]
          lines.push(line)
        end
      end
    end
    lines
  end

  def each_diff_line_near(diff, index, expected_line_code)
    max_number_of_lines = 16

    prev_match_line = nil
    prev_lines = []

    each_diff_line(diff, index) do |full_line, type, line_code, line_new, line_old|
      line = [full_line, type, line_code, line_new, line_old]
      if line_code != expected_line_code
        if type == "match"
          prev_lines.clear
          prev_match_line = line
        else
          prev_lines.push(line)
          prev_lines.shift if prev_lines.length >= max_number_of_lines
        end
      else
        yield(prev_match_line) if !prev_match_line.nil?
        prev_lines.each { |ln| yield(ln) }
        yield(line)
        break
      end
    end
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

  def diff_line_content(line)
    if line.blank?
      " &nbsp;"
    else
      line
    end
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
    source_name = commit.send "#{options[:source]}_name".to_sym
    source_email = commit.send "#{options[:source]}_email".to_sym

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

  def diff_file_mode_changed?(diff)
    diff.a_mode && diff.b_mode && diff.a_mode != diff.b_mode
  end

  def unfold_bottom_class(bottom)
    (bottom) ? 'js-unfold-bottom' : ''
  end

  def view_file_btn(commit_sha, diff, project)
    link_to project_blob_path(project, tree_join(commit_sha, diff.new_path)),
            class: 'btn btn-small view-file js-view-file' do
      raw('View file @') + content_tag(:span, commit_sha[0..6],
                                       class: 'commit-short-id')
    end
  end
end
