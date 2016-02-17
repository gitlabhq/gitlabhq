module IssuesHelper
  def issue_css_classes(issue)
    classes = "issue"
    classes << " closed" if issue.closed?
    classes << " today" if issue.today?
    classes
  end

  # Returns an OpenStruct object suitable for use by <tt>options_from_collection_for_select</tt>
  # to allow filtering issues by an unassigned User or Milestone
  def unassigned_filter
    # Milestone uses :title, Issue uses :name
    OpenStruct.new(id: 0, title: 'None (backlog)', name: 'Unassigned')
  end

  def url_for_project_issues(project = @project, options = {})
    return '' if project.nil?

    if options[:only_path]
      project.issues_tracker.project_path
    else
      project.issues_tracker.project_url
    end
  end

  def url_for_new_issue(project = @project, options = {})
    return '' if project.nil?

    if options[:only_path]
      project.issues_tracker.new_issue_path
    else
      project.issues_tracker.new_issue_url
    end
  end

  def url_for_issue(issue_iid, project = @project, options = {})
    return '' if project.nil?

    if options[:only_path]
      project.issues_tracker.issue_path(issue_iid)
    else
      project.issues_tracker.issue_url(issue_iid)
    end
  end

  def bulk_update_milestone_options
    milestones = @project.milestones.active.reorder(due_date: :asc, title: :asc).to_a
    milestones.unshift(Milestone::None)

    options_from_collection_for_select(milestones, 'id', 'title', params[:milestone_id])
  end

  def milestone_options(object)
    milestones = object.project.milestones.active.reorder(due_date: :asc, title: :asc).to_a
    milestones.unshift(Milestone::None)

    options_from_collection_for_select(milestones, 'id', 'title', object.milestone_id)
  end

  def status_box_class(item)
    if item.respond_to?(:expired?) && item.expired?
      'status-box-expired'
    elsif item.respond_to?(:merged?) && item.merged?
      'status-box-merged'
    elsif item.closed?
      'status-box-closed'
    else
      'status-box-open'
    end
  end

  def issue_button_visibility(issue, closed)
    return 'hidden' if issue.closed? == closed
  end

  def issue_to_atom(xml, issue)
    xml.entry do
      xml.id      namespace_project_issue_url(issue.project.namespace,
                                              issue.project, issue)
      xml.link    href: namespace_project_issue_url(issue.project.namespace,
                                                    issue.project, issue)
      xml.title   truncate(issue.title, length: 80)
      xml.updated issue.created_at.xmlschema
      xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon(issue.author_email))
      xml.author do |author|
        xml.name issue.author_name
        xml.email issue.author_email
      end
      xml.summary issue.title
    end
  end

  def merge_requests_sentence(merge_requests)
    # Sorting based on the `!123` or `group/project!123` reference will sort
    # local merge requests first.
    merge_requests.map do |merge_request|
      merge_request.to_reference(@project)
    end.sort.to_sentence(last_word_connector: ', or ')
  end

  def emoji_icon(name, unicode = nil, aliases = [])
    unicode ||= Emoji.emoji_filename(name) rescue ""

    content_tag :div, "",
      class: "icon emoji-icon emoji-#{unicode}",
      title: name,
      data: {
        aliases: aliases.join(' '),
        emoji: name,
        unicode_name: unicode
      }
  end

  def emoji_author_list(notes, current_user)
    list = notes.map do |note|
             note.author == current_user ? "me" : note.author.name
           end

    list.join(", ")
  end

  def note_active_class(notes, current_user)
    if current_user && notes.pluck(:author_id).include?(current_user.id)
      "active"
    else
      ""
    end
  end

  def awards_sort(awards)
    awards.sort_by do |award, notes|
      if award == "thumbsup"
        0
      elsif award == "thumbsdown"
        1
      else
        2
      end
    end.to_h
  end

  # Required for Banzai::Filter::IssueReferenceFilter
  module_function :url_for_issue
end
