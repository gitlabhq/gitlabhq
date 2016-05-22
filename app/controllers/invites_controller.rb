#encoding: utf-8
class InvitesController < ApplicationController
  before_action :member
  skip_before_action :authenticate_user!, only: :decline

  respond_to :html

  def show

  end

  def accept
    if member.accept_invite!(current_user)
      label, path = source_info(member.source)

      redirect_to path, notice: "已接受作为 #{member.human_access} 访问 #{label} 的邀请。"
    else
      redirect_back_or_default(options: { alert: "此邀请无法被接受。" })
    end
  end

  def decline
    if member.decline_invite!
      label, _ = source_info(member.source)

      path =
        if current_user
          dashboard_projects_path
        else
          new_user_session_path
        end

      redirect_to path, notice: "已拒绝加入 #{label} 的邀请。"
    else
      redirect_back_or_default(options: { alert: "此邀请无法被拒绝。" })
    end
  end

  private

  def member
    return @member if defined?(@member)

    @token = params[:id]
    @member = Member.find_by_invite_token(@token)

    unless @member
      render_404 and return
    end

    @member
  end

  def authenticate_user!
    return if current_user

    notice = "要接受此邀请，请登录"
    notice << "或者创建账号" if current_application_settings.signup_enabled?
    notice << "。"

    store_location_for :user, request.fullpath
    redirect_to new_user_session_path, notice: notice
  end

  def source_info(source)
    case source
    when Project
      project = member.source
      label = "项目 #{project.name_with_namespace}"
      path = namespace_project_path(project.namespace, project)
    when Group
      group = member.source
      label = "群组 #{group.name}"
      path = group_path(group)
    else
      label = "谁知道"
      path = dashboard_projects_path
    end

    [label, path]
  end
end
