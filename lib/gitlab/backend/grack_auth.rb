require_relative 'shell_env'
require_relative 'grack_helpers'

module Grack
  class Auth < Rack::Auth::Basic
    include Helpers

    attr_accessor :user, :project, :ref, :env

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      # Need this patch due to the rails mount

      # Need this if under RELATIVE_URL_ROOT
      unless Gitlab.config.gitlab.relative_url_root.empty?
        # If website is mounted using relative_url_root need to remove it first
        @env['PATH_INFO'] = @request.path.sub(Gitlab.config.gitlab.relative_url_root,'')
      else
        @env['PATH_INFO'] = @request.path
      end

      @env['SCRIPT_NAME'] = ""

      auth!
    end

    private

    def auth!
      return render_not_found unless project

      if @auth.provided?
        return bad_request unless @auth.basic?

        # Authentication with username and password
        login, password = @auth.credentials

        # Allow authentication for GitLab CI service
        # if valid token passed
        if login == "gitlab-ci-token" && project.gitlab_ci?
          token = project.gitlab_ci_service.token

          if token.present? && token == password && service_name == 'git-upload-pack'
            return @app.call(env)
          end
        end

        @user = authenticate_user(login, password)

        if @user
          Gitlab::ShellEnv.set_env(@user)
          @env['REMOTE_USER'] = @auth.username
        else
          return unauthorized
        end

      else
        return unauthorized unless project.public?
      end

      if authorized_git_request?
        @app.call(env)
      else
        unauthorized
      end
    end

    def authorized_git_request?
      authorize_request(service_name)
    end

    def authenticate_user(login, password)
      auth = Gitlab::Auth.new
      auth.find(login, password)
    end

    def authorize_request(service)
      case service
      when 'git-upload-pack'
        can?(user, :download_code, project)
      when'git-receive-pack'
        refs.each do |ref|
          action = if project.protected_branch?(ref)
                     :push_code_to_protected_branches
                   else
                     :push_code
                   end

          return false unless can?(user, action, project)
        end

        # Never let git-receive-pack trough unauthenticated; it's
        # harmless but git < 1.8 doesn't like it
        return false if user.nil?
        true
      else
        false
      end
    end

    def service_name
      if @request.get?
        @request.params['service']
      elsif @request.post?
        File.basename(@request.path)
      else
        nil
      end
    end

    def project
      @project ||= project_by_path(@request.path_info)
    end

    def refs
      @refs ||= parse_refs
    end

    def parse_refs
      input = if @env["HTTP_CONTENT_ENCODING"] =~ /gzip/
                Zlib::GzipReader.new(@request.body).read
              else
                @request.body.read
              end

      # Need to reset seek point
      @request.body.rewind

      # Parse refs
      refs = input.force_encoding('ascii-8bit').scan(/refs\/heads\/([\/\w\.-]+)/n).flatten.compact

      # Cleanup grabare from refs
      # if push to multiple branches
      refs.map do |ref|
        ref.gsub(/00.*/, "")
      end
    end
  end
end
