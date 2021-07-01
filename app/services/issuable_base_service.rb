# frozen_string_literal: true

class IssuableBaseService < ::BaseProjectService
  private

  def self.constructor_container_arg(value)
    # TODO: Dynamically determining the type of a constructor arg based on the class is an antipattern,
    # but the root cause is that Epics::BaseService has some issues that inheritance may not be the
    # appropriate pattern. See more details in comments at the top of Epics::BaseService#initialize.
    # Follow on issue to address this:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/328438

    { project: value }
  end

  attr_accessor :params, :skip_milestone_email

  def initialize(project:, current_user: nil, params: {})
    super

    @skip_milestone_email = @params.delete(:skip_milestone_email)
  end

  def can_admin_issuable?(issuable)
    ability_name = :"admin_#{issuable.to_ability_name}"

    can?(current_user, ability_name, issuable)
  end

  def can_set_issuable_metadata?(issuable)
    ability_name = :"set_#{issuable.to_ability_name}_metadata"

    can?(current_user, ability_name, issuable)
  end

  def filter_params(issuable)
    unless can_set_issuable_metadata?(issuable)
      params.delete(:milestone)
      params.delete(:milestone_id)
      params.delete(:labels)
      params.delete(:add_label_ids)
      params.delete(:add_labels)
      params.delete(:remove_label_ids)
      params.delete(:remove_labels)
      params.delete(:label_ids)
      params.delete(:assignee_ids)
      params.delete(:assignee_id)
      params.delete(:add_assignee_ids)
      params.delete(:remove_assignee_ids)
      params.delete(:due_date)
      params.delete(:canonical_issue_id)
      params.delete(:project)
      params.delete(:discussion_locked)
      params.delete(:confidential)
    end

    filter_assignees(issuable)
    filter_milestone
    filter_labels
    filter_severity(issuable)
  end

  def filter_assignees(issuable)
    filter_assignees_with_key(issuable, :assignee_ids, :assignees)
    filter_assignees_with_key(issuable, :add_assignee_ids, :add_assignees)
    filter_assignees_with_key(issuable, :remove_assignee_ids, :remove_assignees)
  end

  def filter_assignees_with_key(issuable, id_key, key)
    if params[key] && params[id_key].blank?
      params[id_key] = params[key].map(&:id)
    end

    return if params[id_key].blank?

    filter_assignees_using_checks(issuable, id_key)
  end

  def filter_assignees_using_checks(issuable, id_key)
    unless issuable.allows_multiple_assignees?
      params[id_key] = params[id_key].first(1)
    end

    assignee_ids = params[id_key].select { |assignee_id| user_can_read?(issuable, assignee_id) }

    if params[id_key].map(&:to_s) == [IssuableFinder::Params::NONE]
      params[id_key] = []
    elsif assignee_ids.any?
      params[id_key] = assignee_ids
    else
      params.delete(id_key)
    end
  end

  def user_can_read?(issuable, user_id)
    user = User.find_by_id(user_id)

    return false unless user

    ability_name = :"read_#{issuable.to_ability_name}"
    resource     = issuable.persisted? ? issuable : project

    can?(user, ability_name, resource)
  end

  def filter_milestone
    milestone_id = params[:milestone_id]
    return unless milestone_id

    params[:milestone_id] = '' if milestone_id == IssuableFinder::Params::NONE
    groups = project.group&.self_and_ancestors&.select(:id)

    milestone =
      Milestone.for_projects_and_groups([project.id], groups).find_by_id(milestone_id)

    params[:milestone_id] = '' unless milestone
  end

  def filter_labels
    label_ids_to_filter(:add_label_ids, :add_labels, false)
    label_ids_to_filter(:remove_label_ids, :remove_labels, true)
    label_ids_to_filter(:label_ids, :labels, false)
  end

  def label_ids_to_filter(label_id_key, label_key, find_only)
    if params[label_id_key]
      params[label_id_key] = labels_service.filter_labels_ids_in_param(label_id_key)
    elsif params[label_key]
      params[label_id_key] = labels_service.find_or_create_by_titles(label_key, find_only: find_only).map(&:id)
    end

    params.delete(label_key) if params[label_key].nil?
  end

  def labels_service
    @labels_service ||= ::Labels::AvailableLabelsService.new(current_user, parent, params)
  end

  def filter_severity(issuable)
    severity = params.delete(:severity)
    return unless severity && issuable.supports_severity?

    severity = IssuableSeverity::DEFAULT unless IssuableSeverity.severities.key?(severity)
    return if severity == issuable.severity

    params[:issuable_severity_attributes] = { severity: severity }
  end

  def process_label_ids(attributes, existing_label_ids: nil, extra_label_ids: [])
    label_ids = attributes.delete(:label_ids)
    add_label_ids = attributes.delete(:add_label_ids)
    remove_label_ids = attributes.delete(:remove_label_ids)

    new_label_ids = label_ids || existing_label_ids || []
    new_label_ids |= extra_label_ids

    new_label_ids |= add_label_ids if add_label_ids
    new_label_ids -= remove_label_ids if remove_label_ids

    new_label_ids.uniq
  end

  def process_assignee_ids(attributes, existing_assignee_ids: nil, extra_assignee_ids: [])
    process = Issuable::ProcessAssignees.new(assignee_ids: attributes.delete(:assignee_ids),
                                             add_assignee_ids: attributes.delete(:add_assignee_ids),
                                             remove_assignee_ids: attributes.delete(:remove_assignee_ids),
                                             existing_assignee_ids: existing_assignee_ids,
                                             extra_assignee_ids: extra_assignee_ids)
    process.execute
  end

  def handle_quick_actions(issuable)
    merge_quick_actions_into_params!(issuable)
  end

  def merge_quick_actions_into_params!(issuable, only: nil)
    original_description = params.fetch(:description, issuable.description)

    description, command_params =
      QuickActions::InterpretService.new(project, current_user, quick_action_options)
        .execute(original_description, issuable, only: only)

    # Avoid a description already set on an issuable to be overwritten by a nil
    params[:description] = description if description && description != original_description

    params.merge!(command_params)
  end

  def quick_action_options
    {}
  end

  def create(issuable, skip_system_notes: false)
    handle_quick_actions(issuable)
    filter_params(issuable)

    params.delete(:state_event)
    params[:author] ||= current_user
    params[:label_ids] = process_label_ids(params, extra_label_ids: issuable.label_ids.to_a)

    if issuable.respond_to?(:assignee_ids)
      params[:assignee_ids] = process_assignee_ids(params, extra_assignee_ids: issuable.assignee_ids.to_a)
    end

    issuable.assign_attributes(allowed_create_params(params))

    before_create(issuable)

    issuable_saved = issuable.with_transaction_returning_status do
      issuable.save
    end

    if issuable_saved
      create_system_notes(issuable, is_update: false) unless skip_system_notes
      handle_changes(issuable, { params: params })

      after_create(issuable)
      execute_hooks(issuable)

      users_to_invalidate = issuable.allows_reviewers? ? issuable.assignees | issuable.reviewers : issuable.assignees
      invalidate_cache_counts(issuable, users: users_to_invalidate)
      issuable.update_project_counter_caches
    end

    issuable
  end

  def before_create(issuable)
    # To be overridden by subclasses
  end

  def after_create(issuable)
    # To be overridden by subclasses
  end

  def before_update(issuable, skip_spam_check: false)
    # To be overridden by subclasses
  end

  def after_update(issuable)
    # To be overridden by subclasses
  end

  def update(issuable)
    handle_quick_actions(issuable)
    filter_params(issuable)

    change_additional_attributes(issuable)
    old_associations = associations_before_update(issuable)

    assign_requested_labels(issuable)
    assign_requested_assignees(issuable)

    if issuable.changed? || params.present?
      issuable.assign_attributes(allowed_update_params(params))

      if has_title_or_description_changed?(issuable)
        issuable.assign_attributes(last_edited_at: Time.current, last_edited_by: current_user)
      end

      before_update(issuable)

      # Do not touch when saving the issuable if only changes position within a list. We should call
      # this method at this point to capture all possible changes.
      should_touch = update_timestamp?(issuable)

      issuable.updated_by = current_user if should_touch
      # We have to perform this check before saving the issuable as Rails resets
      # the changed fields upon calling #save.
      update_project_counters = issuable.project && update_project_counter_caches?(issuable)
      ensure_milestone_available(issuable)

      issuable_saved = issuable.with_transaction_returning_status do
        issuable.save(touch: should_touch)
      end

      if issuable_saved
        create_system_notes(
          issuable, old_labels: old_associations[:labels], old_milestone: old_associations[:milestone]
        )

        handle_changes(issuable, old_associations: old_associations, params: params)

        new_assignees = issuable.assignees.to_a
        affected_assignees = (old_associations[:assignees] + new_assignees) - (old_associations[:assignees] & new_assignees)

        invalidate_cache_counts(issuable, users: affected_assignees.compact)
        after_update(issuable)
        issuable.create_new_cross_references!(current_user)
        execute_hooks(
          issuable,
          'update',
          old_associations: old_associations
        )

        issuable.update_project_counter_caches if update_project_counters
      end
    end

    issuable
  end

  def update_task(issuable)
    filter_params(issuable)

    if issuable.changed? || params.present?
      issuable.assign_attributes(params.merge(updated_by: current_user,
                                              last_edited_at: Time.current,
                                              last_edited_by: current_user))

      before_update(issuable, skip_spam_check: true)

      if issuable.with_transaction_returning_status { issuable.save }
        create_system_notes(issuable, old_labels: nil)

        handle_task_changes(issuable)
        invalidate_cache_counts(issuable, users: issuable.assignees.to_a)
        after_update(issuable)
        execute_hooks(issuable, 'update', old_associations: nil)

        if issuable.is_a?(MergeRequest)
          Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
            .track_task_item_status_changed(user: current_user)
        end
      end
    end

    issuable
  end

  # Handle the `update_task` event sent from UI.  Attempts to update a specific
  # line in the markdown and cached html, bypassing any unnecessary updates or checks.
  def update_task_event(issuable)
    update_task_params = params.delete(:update_task)
    return unless update_task_params

    tasklist_toggler = TaskListToggleService.new(issuable.description, issuable.description_html,
                                                 line_source: update_task_params[:line_source],
                                                 line_number: update_task_params[:line_number].to_i,
                                                 toggle_as_checked: update_task_params[:checked])

    unless tasklist_toggler.execute
      # if we make it here, the data is much newer than we thought it was - fail fast
      raise ActiveRecord::StaleObjectError
    end

    # by updating the description_html field at the same time,
    # the markdown cache won't be considered invalid
    params[:description]      = tasklist_toggler.updated_markdown
    params[:description_html] = tasklist_toggler.updated_markdown_html

    # since we're updating a very specific line, we don't care whether
    # the `lock_version` sent from the FE is the same or not.  Just
    # make sure the data hasn't changed since we queried it
    params[:lock_version]     = issuable.lock_version

    update_task(issuable)
  end

  def has_title_or_description_changed?(issuable)
    issuable.title_changed? || issuable.description_changed?
  end

  def change_additional_attributes(issuable)
    change_state(issuable)
    change_subscription(issuable)
    change_todo(issuable)
    toggle_award(issuable)
  end

  def change_state(issuable)
    case params.delete(:state_event)
    when 'reopen'
      service_class = reopen_service
    when 'close'
      service_class = close_service
    end

    if service_class
      service_class.new(**service_class.constructor_container_arg(project), current_user: current_user).execute(issuable)
    end
  end

  def change_subscription(issuable)
    case params.delete(:subscription_event)
    when 'subscribe'
      issuable.subscribe(current_user, project)
    when 'unsubscribe'
      issuable.unsubscribe(current_user, project)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def change_todo(issuable)
    case params.delete(:todo_event)
    when 'add'
      todo_service.mark_todo(issuable, current_user)
    when 'done'
      todo = TodosFinder.new(current_user).find_by(target: issuable)
      todo_service.resolve_todo(todo, current_user) if todo
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def assign_requested_labels(issuable)
    label_ids = process_label_ids(params, existing_label_ids: issuable.label_ids)
    return unless ids_changing?(issuable.label_ids, label_ids)

    params[:label_ids] = label_ids
    issuable.touch
  end

  def assign_requested_assignees(issuable)
    return if issuable.is_a?(Epic)

    assignee_ids = process_assignee_ids(params, existing_assignee_ids: issuable.assignee_ids)
    if ids_changing?(issuable.assignee_ids, assignee_ids)
      params[:assignee_ids] = assignee_ids
      issuable.touch
    end
  end

  # Arrays of ids are used, but we should really use sets of ids, so
  # let's have an helper to properly check if some ids are changing
  def ids_changing?(old_array, new_array)
    old_array.sort != new_array.sort
  end

  def toggle_award(issuable)
    award = params.delete(:emoji_award)
    AwardEmojis::ToggleService.new(issuable, award, current_user).execute if award
  end

  def create_system_notes(issuable, **options)
    Issuable::CommonSystemNotesService.new(project: project, current_user: current_user).execute(issuable, **options)
  end

  def associations_before_update(issuable)
    associations =
      {
        labels: issuable.labels.to_a,
        mentioned_users: issuable.mentioned_users(current_user).to_a,
        assignees: issuable.assignees.to_a,
        milestone: issuable.try(:milestone)
      }
    associations[:total_time_spent] = issuable.total_time_spent if issuable.respond_to?(:total_time_spent)
    associations[:time_change] = issuable.time_change if issuable.respond_to?(:time_change)
    associations[:description] = issuable.description
    associations[:reviewers] = issuable.reviewers.to_a if issuable.allows_reviewers?
    associations[:severity] = issuable.severity if issuable.supports_severity?

    associations
  end

  def handle_move_between_ids(issuable_position)
    return unless params[:move_between_ids]

    after_id, before_id = params.delete(:move_between_ids)
    positioning_scope_id = params.delete(positioning_scope_key)

    issuable_before = issuable_for_positioning(before_id, positioning_scope_id)
    issuable_after = issuable_for_positioning(after_id, positioning_scope_id)

    raise ActiveRecord::RecordNotFound unless issuable_before || issuable_after

    issuable_position.move_between(issuable_before, issuable_after)
  end

  def has_changes?(issuable, old_labels: [], old_assignees: [], old_reviewers: [])
    valid_attrs = [:title, :description, :assignee_ids, :reviewer_ids, :milestone_id, :target_branch]

    attrs_changed = valid_attrs.any? do |attr|
      issuable.previous_changes.include?(attr.to_s)
    end

    labels_changed = issuable.labels != old_labels

    assignees_changed = issuable.assignees != old_assignees

    reviewers_changed = issuable.reviewers != old_reviewers if issuable.allows_reviewers?

    attrs_changed || labels_changed || assignees_changed || reviewers_changed
  end

  def invalidate_cache_counts(issuable, users: [])
    users.each do |user|
      user.public_send("invalidate_#{issuable.model_name.singular}_cache_counts") # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  # override if needed
  def handle_changes(issuable, options)
  end

  # override if needed
  def handle_task_changes(issuable)
  end

  # override if needed
  def execute_hooks(issuable, action = 'open', params = {})
  end

  def update_project_counter_caches?(issuable)
    issuable.state_id_changed?
  end

  def parent
    project
  end

  # we need to check this because milestone from milestone_id param is displayed on "new" page
  # where private project milestone could leak without this check
  def ensure_milestone_available(issuable)
    return unless issuable.supports_milestone? && issuable.milestone_id.present?

    issuable.milestone_id = nil unless issuable.milestone_available?
  end

  def update_timestamp?(issuable)
    issuable.changes.keys != ["relative_position"]
  end

  def allowed_create_params(params)
    params
  end

  def allowed_update_params(params)
    params
  end
end

IssuableBaseService.prepend_mod_with('IssuableBaseService')
