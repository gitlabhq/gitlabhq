module Projects::Repositories
  class Push
    include Interactor::Organizer

    def setup
      context.fail!(message: 'Invalid project') if context[:project].blank?
      context.fail!(message: 'Invalid user') if context[:user].blank?
      context.fail!(message: 'Invalid old revision') if context[:oldrev].blank?
      context.fail!(message: 'Invalid new revision') if context[:newrev].blank?
      context.fail!(message: 'Invalid ref') if context[:ref].blank?

      context[:hooks_type] = :push_hooks
    end

    steps = []

    steps << Projects::Repositories::GetPushCommits if push_to_branch?(ref)

    steps << [
      # For branch or tag generate different data hash
      Projects::Repositories::PostReceiveData,
      Events::CreatePushEvent,
      Projects::EnsureSatelliteExists,
      Projects::Repositories::ExpireCache,
      Projects::Repositories::UpdateSize
    ]

    if push_to_branch?(context[:ref])
      if push_to_existing_branch(context[:ref], context[:oldrev])
        steps << Projects::UpdateMergeRequests
      end

      steps << Projects::ProcessCommitMessage
      steps << Projects::ExecuteServices
    end

    # For branch or tag execute diffrent hooks
    steps << Projects::ExecuteHooks

    organize steps.flatten

    private

    def push_to_branch?(ref)
      ref =~ /refs\/heads/
    end

    def push_to_existing_branch?(ref, oldrev)
      # Return if this is not a push to a branch (e.g. new commits)
      push_to_branch?(ref) &&
        oldrev != '0000000000000000000000000000000000000000'
    end
  end
end
