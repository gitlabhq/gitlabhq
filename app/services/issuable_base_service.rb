# frozen_string_literal: true

class IssuableBaseService < ::BaseContainerService
  private

  def available_callbacks
    [
      Issuable::Callbacks::Description,
      Issuable::Callbacks::Milestone,
      Issuable::Callbacks::Labels,
      Issuable::Callbacks::TimeTracking
    ].freeze
  end

  def initialize_callbacks!(issuable)
    @callbacks = available_callbacks.filter_map do |callback_class|
      callback_params = params.slice(*callback_class::ALLOWED_PARAMS)

      next if callback_params.empty?

      callback_class.new(issuable: issuable, current_user: current_user, params: callback_params)
    end

    remove_callback_params
    @callbacks.each(&:after_initialize)
  end

  def remove_callback_params
    available_callbacks.each do |callback_class|
      callback_class::ALLOWED_PARAMS.each { |p| params.delete(p) }
    end
  end

  def self.constructor_container_arg(value)
    # TODO: Dynamically determining the type of a constructor arg based on the class is an antipattern,
    # but the root cause is that Epics::BaseService has some issues that inheritance may not be the
    # appropriate pattern. See more details in comments at the top of Epics::BaseService#initialize.
    # Follow on issue to address this:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/328438

    { container: value }
  end

  attr_accessor :params

  def initialize(container:, current_user: nil, params: {})
    # we need to exclude project params since they may come from external requests. project should always
    # be passed as part of the service's initializer
    super(container: container, current_user: current_user, params: params.except(:project, :project_id))
  end

  def can_admin_issuable?(issuable)
    ability_name = :"admin_#{issuable.to_ability_name}"

    can?(current_user, ability_name, issuable)
  end

  def can_set_issuable_metadata?(issuable)
    ability_name = :"set_#{issuable.to_ability_name}_metadata"

    can?(current_user, ability_name, issuable)
  end

  def can_set_confidentiality?(issuable)
    can?(current_user, :set_confidentiality, issuable)
  end

  def filter_params(issuable)
    unless can_set_issuable_metadata?(issuable)
      params.delete(:assignee_ids)
      params.delete(:assignee_id)
      params.delete(:add_assignee_ids)
      params.delete(:remove_assignee_ids)
      params.delete(:due_date)
      params.delete(:canonical_issue_id)
      params.delete(:project)
      params.delete(:discussion_locked)
    end

    # confidential attribute is a special type of metadata and needs to be allowed to be set
    # by non-members on issues in public projects so that security issues can be reported as confidential.
    params.delete(:confidential) unless can_set_confidentiality?(issuable)
    filter_contact_params(issuable)
    filter_assignees(issuable)
    filter_severity(issuable)
    filter_escalation_status(issuable)
  end

  def filter_assignees(issuable)
    filter_assignees_using_checks(issuable, :assignee_ids)
    filter_assignees_using_checks(issuable, :add_assignee_ids)
    filter_assignees_using_checks(issuable, :remove_assignee_ids)
  end

  def filter_assignees_using_checks(issuable, id_key)
    return if params[id_key].blank?

    unless issuable.allows_multiple_assignees?
      params[id_key] = params[id_key].first(1)
    end

    assignee_ids = User.id_in(params[id_key]).select { |assignee| user_can_read?(issuable, assignee) }.map(&:id)

    if params[id_key].map(&:to_s) == [IssuableFinder::Params::NONE]
      params[id_key] = []
    elsif assignee_ids.any?
      params[id_key] = assignee_ids
    else
      params.delete(id_key)
    end
  end

  def user_can_read?(issuable, user)
    ability_name = :"read_#{issuable.to_ability_name}"

    can?(user, ability_name, issuable.resource_parent)
  end

  def filter_severity(issuable)
    severity = params.delete(:severity)
    return unless severity && issuable.supports_severity?
    return unless can_admin_issuable?(issuable)

    severity = IssuableSeverity::DEFAULT unless IssuableSeverity.severities.key?(severity)
    return if severity == issuable.severity

    params[:issuable_severity_attributes] = { severity: severity }
  end

  def filter_escalation_status(issuable)
    status_params = params.delete(:escalation_status) || {}
    status_params.permit! if status_params.respond_to?(:permit!)

    result = ::IncidentManagement::IssuableEscalationStatuses::PrepareUpdateService.new(
      issuable,
      current_user,
      status_params
    ).execute

    return unless result.success? && result[:escalation_status].present?

    params[:incident_management_issuable_escalation_status_attributes] = result[:escalation_status]
  end

  def process_assignee_ids(attributes, existing_assignee_ids: nil, extra_assignee_ids: [])
    process = Issuable::ProcessAssignees.new(
      assignee_ids: attributes.delete(:assignee_ids),
      add_assignee_ids: attributes.delete(:add_assignee_ids),
      remove_assignee_ids: attributes.delete(:remove_assignee_ids),
      existing_assignee_ids: existing_assignee_ids,
      extra_assignee_ids: extra_assignee_ids
    )

    process.execute
  end

  def handle_quick_actions(issuable)
    merge_quick_actions_into_params!(issuable, params: params)
  end

  # Notes: When the description has been edited, then we need to sanitize and compare with
  # the original description, removing any extra quick actions.
  # If the description has not been edited, then just remove any quick actions
  # in the current description.
  def merge_quick_actions_into_params!(issuable, params:, only: nil)
    target_description = params.fetch(:description, issuable.description)

    description, command_params = QuickActions::InterpretService.new(
      container: container,
      current_user: current_user,
      params: quick_action_options
    ).execute_with_original_text(target_description, issuable, only: only, original_text: issuable.description_was)

    # Avoid a description already set on an issuable to be overwritten by a nil
    params[:description] = description if description && description != target_description

    params.merge!(command_params)
  end

  def quick_action_options
    {}
  end

  def create(issuable, skip_system_notes: false)
    # Set author early since this is used for ability checks
    set_issuable_author(issuable)

    handle_quick_actions(issuable)
    filter_params(issuable)

    params.delete(:state_event)

    if issuable.respond_to?(:assignee_ids)
      params[:assignee_ids] = process_assignee_ids(params, extra_assignee_ids: issuable.assignee_ids.to_a)
    end

    params.delete(:remove_contacts)
    add_crm_contact_emails = params.delete(:add_contacts)

    initialize_callbacks!(issuable)
    issuable.assign_attributes(allowed_create_params(params))

    before_create(issuable)

    issuable_saved = issuable.with_transaction_returning_status do
      @callbacks.each(&:before_create)

      transaction_create(issuable)
    end

    if issuable_saved
      @callbacks.each(&:after_save_commit)

      create_system_notes(issuable, is_update: false) unless skip_system_notes
      handle_changes(issuable, { params: params })

      after_create(issuable)
      set_crm_contacts(issuable, add_crm_contact_emails)
      execute_triggers
      execute_hooks(issuable)

      users_to_invalidate = issuable.allows_reviewers? ? issuable.assignees | issuable.reviewers : issuable.assignees
      invalidate_cache_counts(issuable, users: users_to_invalidate)
      issuable.update_project_counter_caches
    end

    issuable
  end

  def set_issuable_author(issuable)
    author = params.delete(:author)
    author_id = params.delete(:author_id)

    if author
      issuable.author = author
    elsif author_id
      issuable.author_id = author_id
    else
      issuable.author ||= current_user
    end
  end

  def set_crm_contacts(issuable, add_crm_contact_emails, remove_crm_contact_emails = [])
    return unless add_crm_contact_emails.present? || remove_crm_contact_emails.present?

    ::Issues::SetCrmContactsService.new(container: project, current_user: current_user, params: { add_emails: add_crm_contact_emails, remove_emails: remove_crm_contact_emails }).execute(issuable)
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

  def after_update(issuable, old_associations)
    handle_description_updated(issuable)
    handle_label_changes(issuable, old_associations[:labels])
  end

  def execute_triggers
    # This is overridden in EE
  end

  def handle_description_updated(issuable)
    return unless issuable.previous_changes.include?('description')

    GraphqlTriggers.issuable_description_updated(issuable)
  end

  def update(issuable)
    ::Gitlab::Database::LoadBalancing::SessionMap.current(issuable.load_balancer).use_primary!

    old_associations = associations_before_update(issuable)

    # We need to set the lock version early in case some of the callbacks below does a save
    # that increments the lock version. This will prevent a stale lock version when we get to
    # the `#assign_attributes` call below.
    issuable.lock_version = params.delete(:lock_version) if params.key?(:lock_version)

    handle_quick_actions(issuable)
    filter_params(issuable)

    change_additional_attributes(issuable)

    initialize_callbacks!(issuable)

    if issuable.changed? || params.present? || @callbacks.present?
      issuable.assign_attributes(allowed_update_params(params))

      before_update(issuable)

      # We have to perform this check before saving the issuable as Rails resets
      # the changed fields upon calling #save.
      update_project_counters = issuable.project && update_project_counter_caches?(issuable)

      issuable_saved = issuable.with_transaction_returning_status do
        @callbacks.each(&:before_update)

        # Do not touch when saving the issuable if only changes position within a list. We should call
        # this method at this point to capture all possible changes.
        should_touch = update_timestamp?(issuable)

        issuable.updated_by = current_user if should_touch

        transaction_update(issuable, { save_with_touch: should_touch })
      end

      if issuable_saved
        @callbacks.each(&:after_update_commit)
        @callbacks.each(&:after_save_commit)

        create_system_notes(
          issuable, old_labels: old_associations[:labels], old_milestone: old_associations[:milestone]
        )

        handle_changes(issuable, old_associations: old_associations, params: params)

        new_assignees = issuable.assignees.to_a
        affected_assignees = (old_associations[:assignees] + new_assignees) - (old_associations[:assignees] & new_assignees)

        invalidate_cache_counts(issuable, users: affected_assignees.compact)
        after_update(issuable, old_associations)
        issuable.create_new_cross_references!(current_user)
        execute_hooks(
          issuable,
          'update',
          old_associations: old_associations
        )

        execute_triggers
        issuable.update_project_counter_caches if update_project_counters
      end
    end

    trigger_update_subscriptions(issuable, old_associations)

    issuable
  end

  # Overriden in child class
  def trigger_update_subscriptions(issuable, old_associations); end

  def transaction_update(issuable, opts = {})
    touch = opts[:save_with_touch] || false

    issuable.save(touch: touch).tap do |saved|
      if saved
        @callbacks.each(&:after_update)
        @callbacks.each(&:after_save)
      end
    end
  end

  def transaction_create(issuable)
    issuable.save.tap do |saved|
      if saved
        @callbacks.each(&:after_create)
        @callbacks.each(&:after_save)
      end
    end
  end

  def update_task(issuable)
    filter_params(issuable)

    if issuable.changed? || params.present?
      issuable.assign_attributes(params.merge(
        updated_by: current_user,
        last_edited_at: Time.current,
        last_edited_by: current_user
      ))

      before_update(issuable, skip_spam_check: true)

      if issuable.with_transaction_returning_status { transaction_update_task(issuable) }
        create_system_notes(issuable, old_labels: nil)

        handle_task_changes(issuable)
        invalidate_cache_counts(issuable, users: issuable.assignees.to_a)
        # not passing old_associations here to keep `update_task` as fast as possible
        after_update(issuable, {})
        execute_hooks(issuable, 'update', old_associations: nil)

        if issuable.is_a?(MergeRequest)
          Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
            .track_task_item_status_changed(user: current_user)
        end
      end
    end

    issuable
  end

  def transaction_update_task(issuable)
    issuable.save
  end

  # Handle the `update_task` event sent from UI.  Attempts to update a specific
  # line in the markdown and cached html, bypassing any unnecessary updates or checks.
  def update_task_event(issuable)
    update_task_params = params.delete(:update_task)
    return unless update_task_params

    tasklist_toggler = TaskListToggleService.new(
      issuable.description,
      issuable.description_html,
      line_source: update_task_params[:line_source],
      line_number: update_task_params[:line_number].to_i,
      toggle_as_checked: update_task_params[:checked]
    )

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

  def change_additional_attributes(issuable)
    change_state(issuable)
    change_subscription(issuable)
    change_todo(issuable)
    toggle_award(issuable)

    assign_requested_assignees(issuable)
    assign_requested_crm_contacts(issuable)
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

  def assign_requested_crm_contacts(issuable)
    add_crm_contact_emails = params.delete(:add_contacts)
    remove_crm_contact_emails = params.delete(:remove_contacts)
    set_crm_contacts(issuable, add_crm_contact_emails, remove_crm_contact_emails)
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
    associations[:target_branch] = issuable.target_branch if issuable.is_a?(MergeRequest)

    if issuable.supports_escalation? && issuable.escalation_status
      associations[:escalation_status] = issuable.escalation_status.status_name
    end

    associations
  end

  def handle_move_between_ids(issuable_position)
    return unless params[:move_between_ids]

    before_id, after_id = params.delete(:move_between_ids)

    positioning_scope = issuable_position.class.relative_positioning_query_base(issuable_position)

    issuable_before = issuable_for_positioning(before_id, positioning_scope)
    issuable_after = issuable_for_positioning(after_id, positioning_scope)

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

  def has_label_changes?(issuable, old_labels)
    return false if old_labels.nil?

    Set.new(issuable.labels) != Set.new(old_labels)
  end

  def invalidate_cache_counts(issuable, users: [])
    users.each do |user|
      user.public_send("invalidate_#{issuable.noteable_target_type_name}_cache_counts") # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  # override if needed
  def handle_label_changes(issuable, old_labels)
    return false unless has_label_changes?(issuable, old_labels)

    # reset to preserve the label sort order (title ASC)
    issuable.labels.reset

    GraphqlTriggers.issuable_labels_updated(issuable)

    # return true here to avoid checking for label changes in sub classes
    true
  end

  # override if needed
  def handle_changes(issuable, options); end

  # override if needed
  def handle_task_changes(issuable); end

  # override if needed
  def execute_hooks(issuable, action = 'open', params = {}); end

  def update_project_counter_caches?(issuable)
    issuable.state_id_changed?
  end

  def parent
    project
  end

  def update_timestamp?(issuable)
    issuable.changes.keys != ["relative_position"]
  end

  def allowed_create_params(params)
    params.except(:observability_links)
  end

  def allowed_update_params(params)
    params
  end

  def update_issuable_sla(issuable)
    return unless issuable_sla = issuable.issuable_sla

    issuable_sla.update(issuable_closed: issuable.closed?)
  end

  def filter_contact_params(issuable)
    return if params.slice(:add_contacts, :remove_contacts).empty?
    return if can?(current_user, :set_issue_crm_contacts, issuable)

    params.extract!(:add_contacts, :remove_contacts)
  end
end

IssuableBaseService.prepend_mod_with('IssuableBaseService')
