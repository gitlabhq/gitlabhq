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

    url =
      if options[:only_path]
        project.issues_tracker.project_path
      else
        project.issues_tracker.project_url
      end

    # Ensure we return a valid URL to prevent possible XSS.
    URI.parse(url).to_s
  rescue URI::InvalidURIError
    ''
  end

  def url_for_new_issue(project = @project, options = {})
    return '' if project.nil?

    url =
      if options[:only_path]
        project.issues_tracker.new_issue_path
      else
        project.issues_tracker.new_issue_url
      end

    # Ensure we return a valid URL to prevent possible XSS.
    URI.parse(url).to_s
  rescue URI::InvalidURIError
    ''
  end

  def url_for_issue(issue_iid, project = @project, options = {})
    return '' if project.nil?

    url =
      if options[:only_path]
        project.issues_tracker.issue_path(issue_iid)
      else
        project.issues_tracker.issue_url(issue_iid)
      end

    # Ensure we return a valid URL to prevent possible XSS.
    URI.parse(url).to_s
  rescue URI::InvalidURIError
    ''
  end

  def bulk_update_milestone_options
    milestones = @project.milestones.active.reorder(due_date: :asc, title: :asc).to_a
    milestones.unshift(Milestone::None)

    options_from_collection_for_select(milestones, 'id', 'title', params[:milestone_id])
  end

  def milestone_options(object)
    milestones = object.project.milestones.active.reorder(due_date: :asc, title: :asc).to_a
    milestones.unshift(object.milestone) if object.milestone.present? && object.milestone.closed?
    milestones.unshift(Milestone::None)

    options_from_collection_for_select(milestones, 'id', 'title', object.milestone_id)
  end

  def project_options(issuable, current_user, ability: :read_project)
    projects = current_user.authorized_projects
    projects = projects.select do |project|
      current_user.can?(ability, project)
    end

    no_project = OpenStruct.new(id: 0, name_with_namespace: 'No project')
    projects.unshift(no_project)
    projects.delete(issuable.project)

    options_from_collection_for_select(projects, :id, :name_with_namespace)
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

  def merge_requests_sentence(merge_requests)
    # Sorting based on the `!123` or `group/project!123` reference will sort
    # local merge requests first.
    merge_requests.map do |merge_request|
      merge_request.to_reference(@project)
    end.sort.to_sentence(last_word_connector: ', or ')
  end

  def confidential_icon(issue)
    icon('eye-slash') if issue.confidential?
  end

  def emoji_icon(name, unicode = nil, aliases = [], sprite: true)
    unicode ||= Gitlab::Emoji.emoji_filename(name) rescue ""

    data = {
      aliases: aliases.join(" "),
      emoji: name,
      unicode_name: unicode
    }

    if sprite
      # Emoji icons for the emoji menu, these use a spritesheet.
      content_tag :div, "",
        class: "icon emoji-icon emoji-#{unicode}",
        title: name,
        data: data
    else
      # Emoji icons displayed separately, used for the awards already given
      # to an issue or merge request.
      content_tag :img, "",
        class: "icon emoji",
        title: name,
        height: "20px",
        width: "20px",
        src: url_to_image("#{unicode}.png"),
        data: data
    end
  end

  def award_user_list(awards, current_user)
    awards.map do |award|
      award.user == current_user ? 'me' : award.user.name
    end.join(', ')
  end

  def award_active_class(awards, current_user)
    if current_user && awards.find { |a| a.user_id == current_user.id }
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

  def due_date_options
    options = [
      Issue::AnyDueDate,
      Issue::NoDueDate,
      Issue::DueThisWeek,
      Issue::DueThisMonth,
      Issue::Overdue
    ]

    options_from_collection_for_select(options, 'name', 'title', params[:due_date])
  end

  def issues_weight_options(selected = nil, edit: false)
    weights = edit ? edit_weights : issue_weights

    options_for_select(weights, selected || params[:weight])
  end

  def issue_weights(weight_array = Issue.weight_options)
    weight_array.zip(weight_array)
  end

  def edit_weights
    issue_weights([Issue::WEIGHT_NONE] + Issue::WEIGHT_RANGE.to_a)
  end

  # Required for Banzai::Filter::IssueReferenceFilter
  module_function :url_for_issue
end
