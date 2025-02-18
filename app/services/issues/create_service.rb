# frozen_string_literal: true

module Issues
  class CreateService < Issues::BaseService
    include ResolveDiscussions
    prepend RateLimitedService
    include ::Services::ReturnServiceResponses

    rate_limit key: :issues_create,
      opts: { scope: [:project, :current_user, :external_author] }

    def initialize(container:, current_user: nil, params: {}, build_service: nil, perform_spam_check: true)
      @extra_params = params.delete(:extra_params) || {}
      super(container: container, current_user: current_user, params: params)
      @perform_spam_check = perform_spam_check
      @build_service = build_service ||
        BuildService.new(container: project, current_user: current_user, params: params)
    end

    def execute(skip_system_notes: false)
      return error(_('Operation not allowed'), 403) unless @current_user.can?(authorization_action, container)

      # We should not initialize the callback classes during the build service execution because these will be
      # initialized when we call #create below
      @issue = @build_service.execute(initialize_callbacks: false)

      # issue_type and work_item_type are set in BuildService, so we can delete it from params, in later phase
      # it can be set also from quick actions
      [:issue_type, :work_item_type, :work_item_type_id].each { |attribute| params.delete(attribute) }

      handle_move_between_ids(@issue)

      @add_related_issue ||= params.delete(:add_related_issue)
      filter_resolve_discussion_params

      issue = create(@issue, skip_system_notes: skip_system_notes)

      if issue.persisted?
        success(issue: issue)
      else
        error(issue.errors.full_messages, 422, pass_back: { issue: issue })
      end
    end

    def external_author
      params[:external_author] # present when creating an issue using service desk (email: from)
    end

    def before_create(issue)
      issue.check_for_spam(user: current_user, action: :create) if perform_spam_check

      assign_description_from_template(issue)
      after_commit_tasks(current_user, issue)
    end

    # Add new items to Issues::AfterCreateService if they can be performed in Sidekiq
    def after_create(issue)
      user_agent_detail_service.create
      handle_add_related_issue(issue)
      resolve_discussions_with_issue(issue)
      handle_escalation_status_change(issue)
      create_timeline_event(issue)
      try_to_associate_contacts(issue)

      super
    end

    def handle_changes(issue, options)
      super
      old_associations = options.fetch(:old_associations, {})
      old_assignees = old_associations.fetch(:assignees, [])

      handle_assignee_changes(issue, old_assignees)
    end

    def handle_assignee_changes(issue, old_assignees)
      return if issue.assignees == old_assignees

      create_assignee_note(issue, old_assignees)
      Gitlab::ResourceEvents::AssignmentEventRecorder.new(parent: issue, old_assignees: old_assignees).record
    end

    def resolve_discussions_with_issue(issue)
      return if discussions_to_resolve.empty?

      Discussions::ResolveService.new(
        project,
        current_user,
        one_or_more_discussions: discussions_to_resolve,
        follow_up_issue: issue
      ).execute
    end

    private

    def authorization_action
      :create_issue
    end

    attr_reader :perform_spam_check, :extra_params

    def create_timeline_event(issue)
      return unless issue.work_item_type&.incident?

      IncidentManagement::TimelineEvents::CreateService.create_incident(issue, current_user)
    end

    def user_agent_detail_service
      UserAgentDetailService.new(spammable: @issue, perform_spam_check: perform_spam_check)
    end

    def handle_add_related_issue(issue)
      return unless @add_related_issue

      IssueLinks::CreateService.new(issue, issue.author, { target_issuable: @add_related_issue }).execute
    end

    def try_to_associate_contacts(issue)
      return unless issue.external_author
      return unless current_user.can?(:set_issue_crm_contacts, issue)

      contacts = [issue.external_author]
      contacts.concat extra_params[:cc] unless extra_params[:cc].nil?

      set_crm_contacts(issue, contacts)
    end

    def assign_description_from_template(issue)
      return if issue.description.present?

      # Find the exact name for the default template (if the project has one).
      # Since there are multiple possibilities regarding the capitalization(s) that the
      # default template file name can have, getting the exact template name here will
      # allow us to extract the contents later, and bail early if the project does not have
      # a default template
      templates = TemplateFinder.all_template_names(project, :issues)
      template = templates.values.flatten.find { |tmpl| tmpl[:name].casecmp?('default') }

      return unless template

      begin
        default_template = TemplateFinder.build(
          :issues,
          project,
          {
            name: template[:name],
            source_template_project_id: template[:project_id]
          }
        ).execute
      rescue ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
        nil
      end

      issue.description = default_template.content if default_template.present?
    end

    def after_commit_tasks(user, issue)
      issue.run_after_commit do
        NewIssueWorker.perform_async(issue.id, user.id, issue.class.to_s)
        Issues::PlacementWorker.perform_async(nil, issue.project_id)
      end
    end
  end
end

Issues::CreateService.prepend_mod
