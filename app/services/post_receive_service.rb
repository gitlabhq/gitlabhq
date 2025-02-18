# frozen_string_literal: true

# PostReceiveService class
#
# Used for scheduling related jobs after a push action has been performed
class PostReceiveService
  attr_reader :user, :repository, :project, :params

  def initialize(user, repository, project, params)
    @user = user
    @repository = repository
    @project = project
    @params = params
  end

  def execute
    response = Gitlab::InternalPostReceive::Response.new

    push_options = Gitlab::PushOptions.new(params[:push_options])
    mr_options = push_options.get(:merge_request)

    response.reference_counter_decreased = Gitlab::ReferenceCounter.new(params[:gl_repository]).decrease

    # The PostReceive worker will normally invalidate the cache. However, it
    # runs asynchronously. If push options require us to create a new merge
    # request synchronously, we can't rely on that, so invalidate the cache here
    repository&.expire_branches_cache if mr_options&.fetch(:create, false)

    if project && repository && Feature.enabled?(:rename_post_receive_worker, project, type: :gitlab_com_derisk)
      Repositories::PostReceiveWorker.perform_async(params[:gl_repository], params[:identifier],
        params[:changes], push_options.as_json)
    else
      PostReceive.perform_async(params[:gl_repository], params[:identifier],
        params[:changes], push_options.as_json)
    end

    if mr_options.present?
      message = process_mr_push_options(mr_options, params[:changes])
      response.add_alert_message(message)
    end

    response.add_alert_message(broadcast_message)
    response.add_merge_request_urls(merge_request_urls)

    # Neither User nor Repository are guaranteed to be returned; an orphaned write deploy
    # key could be used
    if user && repository
      redirect_message = Gitlab::Checks::ContainerMoved.fetch_message(user, repository)
      project_created_message = Gitlab::Checks::ProjectCreated.fetch_message(user, repository)

      response.add_basic_message(redirect_message)
      response.add_basic_message(project_created_message)
    end

    response
  end

  def process_mr_push_options(push_options, changes)
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/28494')
    return unless repository

    unless repository.repo_type.project?
      return push_options_warning('Push options are only supported for projects')
    end

    service = ::MergeRequests::PushOptionsHandlerService.new(
      project: project, current_user: user, changes: changes, push_options: push_options
    ).execute

    if service.errors.present?
      push_options_warning(service.errors.join("\n\n"))
    end
  end

  def push_options_warning(warning)
    options = Array.wrap(params[:push_options]).map { |p| "'#{p}'" }.join(' ')
    "WARNINGS:\nError encountered with push options #{options}: #{warning}"
  end

  def merge_request_urls
    return [] unless repository&.repo_type&.project?

    ::MergeRequests::GetUrlsService.new(project: project).execute(params[:changes])
  end

  private

  def broadcast_message
    banner = nil
    user_access_level = if project && user
                          user.max_member_access_for_project(project.id)
                        end

    if project
      scoped_messages =
        System::BroadcastMessage.current_banner_messages(
          current_path: project.full_path,
          user_access_level: user_access_level
        ).select do |message|
          message.target_path.present? && message.matches_current_path(project.full_path) && message.show_in_cli?
        end

      banner = scoped_messages.last
    end

    banner ||= System::BroadcastMessage.current_show_in_cli_banner_messages(user_access_level: user_access_level).last

    banner&.message
  end
end

PostReceiveService.prepend_mod_with('PostReceiveService')
