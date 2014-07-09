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

  def parallel_diff_lines(project, commit, diff, file)
    old_file = project.repository.blob_at(commit.parent_id, diff.old_path) if commit.parent_id
    deleted_lines = {}
    added_lines = {}
    each_diff_line(diff, 0) do |line, type, line_code, line_new, line_old|
      if type == "old"
        deleted_lines[line_old] = { line_code: line_code, type: type, line: line }
      elsif type == "new"
        added_lines[line_new]   = { line_code: line_code, type: type, line: line }
      end
    end
    max_length = old_file ? [old_file.loc, file.loc].max : file.loc

    offset1 = 0
    offset2 = 0
    old_lines = []
    new_lines = []

    max_length.times do |line_index|
      line_index1 = line_index - offset1
      line_index2 = line_index - offset2
      deleted_line = deleted_lines[line_index1 + 1]
      added_line = added_lines[line_index2 + 1]
      old_line = old_file.lines[line_index1] if old_file
      new_line = file.lines[line_index2]

      if deleted_line && added_line
      elsif deleted_line
        new_line = nil
        offset2 += 1
      elsif added_line
        old_line = nil
        offset1 += 1
      end

      old_lines[line_index] = DiffLine.new
      new_lines[line_index] = DiffLine.new

      # old
      if line_index == 0 && diff.new_file
        old_lines[line_index].type = :file_created
        old_lines[line_index].content = 'File was created'
      elsif deleted_line
        old_lines[line_index].type = :deleted
        old_lines[line_index].content = old_line
        old_lines[line_index].num = line_index1 + 1
        old_lines[line_index].code = deleted_line[:line_code]
      elsif old_line
        old_lines[line_index].type = :no_change
        old_lines[line_index].content = old_line
        old_lines[line_index].num = line_index1 + 1
      else
        old_lines[line_index].type = :added
      end

      # new
      if line_index == 0 && diff.deleted_file
        new_lines[line_index].type = :file_deleted
        new_lines[line_index].content = "File was deleted"
      elsif added_line
        new_lines[line_index].type = :added
        new_lines[line_index].num = line_index2 + 1
        new_lines[line_index].content = new_line
        new_lines[line_index].code = added_line[:line_code]
      elsif new_line
        new_lines[line_index].type = :no_change
        new_lines[line_index].num = line_index2 + 1
        new_lines[line_index].content = new_line
      else
        new_lines[line_index].type = :deleted
      end
    end

    return old_lines, new_lines
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
end
