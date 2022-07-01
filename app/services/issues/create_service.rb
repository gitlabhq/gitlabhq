# frozen_string_literal: true

module Issues
  class CreateService < Issues::BaseService
    include ResolveDiscussions
    prepend RateLimitedService

    rate_limit key: :issues_create,
               opts: { scope: [:project, :current_user, :external_author] }

    # NOTE: For Issues::CreateService, we require the spam_params and do not default it to nil, because
    # spam_checking is likely to be necessary.  However, if there is not a request available in scope
    # in the caller (for example, an issue created via email) and the required arguments to the
    # SpamParams constructor are not otherwise available, spam_params: must be explicitly passed as nil.
    def initialize(project:, current_user: nil, params: {}, spam_params:, build_service: nil)
      @extra_params = params.delete(:extra_params) || {}
      super(project: project, current_user: current_user, params: params)
      @spam_params = spam_params
      @build_service = build_service || BuildService.new(project: project, current_user: current_user, params: params)
    end

    def execute(skip_system_notes: false)
      @issue = @build_service.execute

      handle_move_between_ids(@issue)

      @add_related_issue ||= params.delete(:add_related_issue)
      filter_resolve_discussion_params

      create(@issue, skip_system_notes: skip_system_notes)
    end

    def external_author
      params[:external_author] # present when creating an issue using service desk (email: from)
    end

    def before_create(issue)
      Spam::SpamActionService.new(
        spammable: issue,
        spam_params: spam_params,
        user: current_user,
        action: :create
      ).execute

      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      issue.run_after_commit do
        NewIssueWorker.perform_async(issue.id, user.id)
        Issues::PlacementWorker.perform_async(nil, issue.project_id)
        Namespaces::OnboardingIssueCreatedWorker.perform_async(issue.namespace.id)
      end
    end

    # Add new items to Issues::AfterCreateService if they can be performed in Sidekiq
    def after_create(issue)
      user_agent_detail_service.create
      handle_add_related_issue(issue)
      resolve_discussions_with_issue(issue)
      create_escalation_status(issue)
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
    end

    def resolve_discussions_with_issue(issue)
      return if discussions_to_resolve.empty?

      Discussions::ResolveService.new(project, current_user,
                                      one_or_more_discussions: discussions_to_resolve,
                                      follow_up_issue: issue).execute
    end

    private

    attr_reader :spam_params, :extra_params

    def create_escalation_status(issue)
      ::IncidentManagement::IssuableEscalationStatuses::CreateService.new(issue).execute if issue.supports_escalation?
    end

    def create_timeline_event(issue)
      return unless issue.incident?

      IncidentManagement::TimelineEvents::CreateService.create_incident(issue, current_user)
    end

    def user_agent_detail_service
      UserAgentDetailService.new(spammable: @issue, spam_params: spam_params)
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
  end
end

Issues::CreateService.prepend_mod
