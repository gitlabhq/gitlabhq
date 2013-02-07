module Grack
  class Auth < Rack::Auth::Basic
    attr_accessor :user, :project

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      # Pass Gitolite update hook
      ENV['GL_BYPASS_UPDATE_HOOK'] = "true"

      # Need this patch due to the rails mount
      @env['PATH_INFO'] = @request.path
      @env['SCRIPT_NAME'] = ""

      return render_not_found unless project
      return unauthorized unless project.public || @auth.provided?
      return bad_request if @auth.provided? && !@auth.basic?

      if valid?
        if @auth.provided?
          @env['REMOTE_USER'] = @auth.username
        end
        return @app.call(env)
      else
        unauthorized
      end
    end

    def valid?
      if @auth.provided?
        # Authentication with username and password
        login, password = @auth.credentials
        self.user = User.find_by_email(login) || User.find_by_username(login)
        return false unless user.try(:valid_password?, password)

        # Set GL_USER env variable
        ENV['GL_USER'] = user.email
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
      project.public || can?(user, :download_code, project)
    end

    def validate_post_request
      if @request.path_info.end_with?('git-upload-pack')
        project.public || can?(user, :download_code, project)
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
      /refs\/heads\/([\w\.-]+)/.match(input).to_a.last
    end

    def project
      unless instance_variable_defined? :@project
        # Find project by PATH_INFO from env
        if m = /^\/([\w\.\/-]+)\.git/.match(@request.path_info).to_a
          @project = Project.find_with_namespace(m.last)
        end
      end
      return @project
    end

    PLAIN_TYPE = {"Content-Type" => "text/plain"}

    def render_not_found
      [404, PLAIN_TYPE, ["Not Found"]]
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
