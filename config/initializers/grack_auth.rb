module Grack
  class Auth < Rack::Auth::Basic

    def valid?
      # Authentication with username and password
      email, password = @auth.credentials
      user = User.find_by_email(email)
      return false unless user.valid_password?(password)

      # Find project by PATH_INFO from env
      if m = /^\/([\w-]+).git/.match(@env['PATH_INFO']).to_a
        return false unless project = Project.find_by_path(m.last)
      end

      # Git upload and receive
      if @env['REQUEST_METHOD'] == 'GET'
        true
      elsif @env['REQUEST_METHOD'] == 'POST'
        if @env['REQUEST_URI'].end_with?('git-upload-pack')
          return project.dev_access_for?(user)
        elsif @env['REQUEST_URI'].end_with?('git-upload-pack')
          #TODO master branch protection
          return project.dev_access_for?(user)
        else
          false
        end
      end

    end# valid?
  end# Auth
end# Grack
