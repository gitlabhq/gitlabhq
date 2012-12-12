module Grack
  class Auth < Rack::Auth::Basic
    attr_accessor :user, :project

    def valid?
      # Authentication with username and password
      login, password = @auth.credentials

      self.user = User.find_by_email(login) || User.find_by_username(login)

      return false unless user.try(:valid_password?, password)

      email = user.email

      # Set GL_USER env variable
      ENV['GL_USER'] = email
      # Pass Gitolite update hook
      ENV['GL_BYPASS_UPDATE_HOOK'] = "true"

      # Need this patch due to the rails mount
      @env['PATH_INFO'] = @request.path
      @env['SCRIPT_NAME'] = ""

      # Find project by PATH_INFO from env
      if m = /^\/([\w\.\/-]+)\.git/.match(@request.path_info).to_a
        self.project = Project.find_with_namespace(m.last)
        return false unless project
      end

      # Git upload and receive
      if @request.get?
        validate_get_request
      elsif @request.post?
        validate_post_request
      else
        false
      end
    end

    def validate_get_request
      can?(user, :download_code, project)
    end

    def validate_post_request
      if @request.path_info.end_with?('git-upload-pack')
        can?(user, :download_code, project)
      elsif @request.path_info.end_with?('git-receive-pack')
        action = if project.protected_branch?(current_ref)
                   :push_code_to_protected_branches
                 else
                   :push_code
                 end

        can?(user, action, project)
      else
        false
      end
    end

    def can?(object, action, subject)
      abilities.allowed?(object, action, subject)
    end

    def current_ref
      if @env["HTTP_CONTENT_ENCODING"] =~ /gzip/
        input = Zlib::GzipReader.new(@request.body).read
      else
        input = @request.body.read
      end
      # Need to reset seek point
      @request.body.rewind
      /refs\/heads\/([\w\.-]+)/.match(input).to_a.first
    end

    protected

    def abilities
      @abilities ||= begin
                       abilities = Six.new
                       abilities << Ability
                       abilities
                     end
    end
  end# Auth
end# Grack
