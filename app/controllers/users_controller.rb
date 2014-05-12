class UsersController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show]
  layout :determine_layout

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects.accessible_to(current_user)
    @user_projects = @user.authorized_projects.accessible_to(@user)
    @repositories = @user_projects.map(&:repository)

    if !current_user && @projects.empty?
      return authenticate_user!
    end
    @groups = @user.groups.accessible_to(current_user)
    @events = @user.recent_events.where(project_id: @projects.pluck(:id)).limit(20)
    @title = @user.name

    @repositories.collect { |raw|
      if raw.exists?
        commits_log = raw.graph_log
        @commits_log = commits_log.select do |u_email|
          u_email[:author_email] == @user.email
        end.map do |graph_log|
          Date.parse(graph_log[:date]).to_time.to_i
        end
        @timestamps = {}
        @commits_log = @commits_log.group_by { |commit_date|
          commit_date }.map { |k, v|
                    hash = {"#{k}" => v.count}
                    @timestamps.merge!(hash)
                  }
                 
        if @timestamps.empty?
          @timeCopy = DateTime.now.to_date()
        else
          @timeCopy = Time.at(@timestamps.first.first.to_i).to_date
          @timestamps = @timestamps.to_json
        end   

      end
    }
  end

  def determine_layout
    if current_user
      'navless'
    else
      'public_users'
    end
  end
end
