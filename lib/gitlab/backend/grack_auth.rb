module Grack
  class Auth < Rack::Auth::Basic

    def valid?
      # Authentication with username and password
      email, password = @auth.credentials
      user = User.find_by_email(email)
      return false unless user.try(:valid_password?, password)

      # Set GL_USER env variable
      ENV['GL_USER'] = email
      # Pass Gitolite update hook
      ENV['GL_BYPASS_UPDATE_HOOK'] = "true"

      # Need this patch due to the rails mount
      @env['PATH_INFO'] = @request.path
      @env['SCRIPT_NAME'] = ""

      # Find project by PATH_INFO from env
      if m = /^\/([\w-]+).git/.match(@request.path_info).to_a
        return false unless project = Project.find_by_path(m.last)
      end

      # Git upload and receive
      if @request.get?
        true
      elsif @request.post?
        if @request.path_info.end_with?('git-upload-pack')
          return project.dev_access_for?(user)
        elsif @request.path_info.end_with?('git-receive-pack')
          if project.protected_branches.map(&:name).include?(current_ref)
            project.master_access_for?(user)
          else
            project.dev_access_for?(user)
          end
        else
          false
        end
      else
        false
      end
    end# valid?

    def current_ref
      if @env["HTTP_CONTENT_ENCODING"] =~ /gzip/
        input = Zlib::GzipReader.new(@request.body).read
      else
        input = @request.body.read
      end
      # Need to reset seek point
      @request.body.rewind
      /refs\/heads\/([\w-]+)/.match(input).to_a.first
    end
  end# Auth
end# Grack
