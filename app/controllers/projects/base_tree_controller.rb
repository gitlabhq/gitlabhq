class Projects::BaseTreeController < Projects::ApplicationController
  include ExtractsPath

  before_filter :authorize_read_project!
  before_filter :authorize_download_code!
  before_filter :require_non_empty_project

  protected

  ON_MY_FORK_CHECKBOX_CHECKED_DEFAULT = true

  def set_new_mr_vars
    prefix = 'patch-'
    gon.new_branch_name_this = @repository.free_branch_name(prefix)
    if current_user.already_forked?(@project)
      gon.new_branch_name_fork = current_user.fork_of(@project).
        repository.free_branch_name(prefix)
    else
      gon.new_branch_name_fork = gon.new_branch_name_this
    end
    can_edit_branch = @project.can_push_to?(current_user, @ref)
    @create_merge_request_checkbox_disabled = !can_edit_branch
    @create_merge_request_checkbox_checked = if !can_edit_branch
                                               true
                                             elsif params[:create_merge_request]
                                               true
                                             else
                                               false
                                             end
    @source_project_show_my_fork = if !can_edit_branch
                                     true
                                   elsif params[:on_my_fork]
                                     true
                                   else
                                     false
                                   end
    @on_my_fork_checkbox_disabled = !can_edit_branch
    @on_my_fork_checkbox_checked = if @source_project_show_my_fork
                                     true
                                   elsif @create_merge_request_checkbox_checked
                                     false
                                   else
                                     ON_MY_FORK_CHECKBOX_CHECKED_DEFAULT
                                   end
    params[:new_branch_name] ||= if @on_my_fork_checkbox_checked
                                   gon.new_branch_name_fork
                                 else
                                   gon.new_branch_name_this
                                 end
  end

  def update_new_mr(service, path)
    set_new_mr_vars
    source_project = @project
    target_project = @project
    source_branch_name = @ref
    created_new_branch = false
    if @create_merge_request_checkbox_checked
      source_branch_name = params[:new_branch_name]
      if @source_project_show_my_fork
        if current_user.already_forked?(target_project)
          source_project = current_user.fork_of(target_project)
        else
          source_project = Projects::ForkService.
            new(target_project, current_user).execute
          if source_project.errors.any?
            flash[:alert] = source_project.errors.full_messages.first
            render :show
            return
          end
        end
      end
      result = CreateBranchService.new(source_project, current_user).
        execute(source_branch_name, @ref)
      if result[:status] == :error
        flash[:alert] = result[:message]
        render :show
        return
      end
      created_new_branch = true
    end
    result = service.new(source_project, current_user, params,
                         source_branch_name, path).execute
    if result[:status] == :success
      flash[:notice] = 'Your changes have been successfully committed'
      if @create_merge_request_checkbox_checked
        redirect_to new_project_merge_request_path(
          source_project,
          merge_request: {
            source_branch:     source_branch_name,
            target_project_id: target_project.id
          }
        )
      else
        if from_merge_request
          from_merge_request.reload_code
        end
        redirect_to after_edit_path
      end
    else
      if created_new_branch
        source_project.repository.rm_branch(source_branch_name)
      end
      flash[:alert] = result[:message]
      render :show
    end
  end

  def authorize_show_blob_edit!
    return access_denied! unless can_show_blob_edit?
  end

  def from_merge_request
    # If blob edit was initiated from merge request page
    @from_merge_request ||= MergeRequest.
      find_by(id: params[:from_merge_request_id])
  end
end

