# frozen_string_literal: true

module Issues
  class CreateService < Issues::BaseService
    include ResolveDiscussions

    def execute(skip_system_notes: false)
      @request = params.delete(:request)
      @spam_params = Spam::SpamActionService.filter_spam_params!(params, @request)

      @issue = BuildService.new(project: project, current_user: current_user, params: params).execute

      filter_resolve_discussion_params

      create(@issue, skip_system_notes: skip_system_notes)
    end

    def before_create(issue)
      Spam::SpamActionService.new(
        spammable: issue,
        request: request,
        user: current_user,
        action: :create
      ).execute(spam_params: spam_params)

      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      issue.run_after_commit do
        NewIssueWorker.perform_async(issue.id, user.id)
        IssuePlacementWorker.perform_async(nil, issue.project_id)
        Namespaces::OnboardingIssueCreatedWorker.perform_async(issue.namespace.id)
      end
    end

    # Add new items to Issues::AfterCreateService if they can be performed in Sidekiq
    def after_create(issue)
      add_incident_label(issue)
      user_agent_detail_service.create
      resolve_discussions_with_issue(issue)

      super
    end

    def resolve_discussions_with_issue(issue)
      return if discussions_to_resolve.empty?

      Discussions::ResolveService.new(project, current_user,
                                      one_or_more_discussions: discussions_to_resolve,
                                      follow_up_issue: issue).execute
    end

    private

    attr_reader :request, :spam_params

    def user_agent_detail_service
      UserAgentDetailService.new(@issue, request)
    end

    # Applies label "incident" (creates it if missing) to incident issues.
    # For use in "after" hooks only to ensure we are not appyling
    # labels prematurely.
    def add_incident_label(issue)
      return unless issue.incident?

      label = ::IncidentManagement::CreateIncidentLabelService
        .new(project, current_user)
        .execute
        .payload[:label]

      return if issue.label_ids.include?(label.id)

      issue.labels << label
    end
  end
end

Issues::CreateService.prepend_mod
