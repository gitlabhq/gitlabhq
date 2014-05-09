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

    @repositories.collect { |x|
      if x.exists?
        lol = x.graph_log
        #print lol
        @lol = lol.select do |e|
          e[:author_email] == @user.email
          # if e[:author_email] == @user.email
          #   puts e[:date]
          # end
        end.map do |graph_log|
          Date.parse(graph_log[:date]).to_time.to_i
        end
        @timestamps = {}
        @lol = @lol.group_by { |d|
          d }.map { |k, v|
                    hash = {"#{k}" => v.count}
                    @timestamps.merge!(hash)
                  }
        @timestamps = @timestamps.to_json
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
