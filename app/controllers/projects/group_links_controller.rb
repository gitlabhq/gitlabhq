#-------------------------------------------------------------------
#
# The GitLab Enterprise Edition (EE) license
#
# Copyright (c) 2013 GitLab.com
#
# All Rights Reserved. No part of this software may be reproduced without
# prior permission of GitLab.com. By using this software you agree to be
# bound by the GitLab Enterprise Support Subscription Terms.
#
#-------------------------------------------------------------------

class Projects::GroupLinksController < Projects::ApplicationController
  layout 'project_settings'
  before_filter :authorize_admin_project!

  def index
    @group_links = project.project_group_links.all
    @available_groups = Group.scoped
    @available_groups -= project.invited_groups
    @available_groups -= [project.group]
  end

  def create
    link = project.project_group_links.new
    link.group_id = params[:group_id]
    link.save

    redirect_to project_group_links_path(project)
  end

  def destroy
    project.project_group_links.find(params[:id]).destroy

    redirect_to project_group_links_path(project)
  end
end

