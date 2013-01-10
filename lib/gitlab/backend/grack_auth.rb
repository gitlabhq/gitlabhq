module Grack
  class Auth < Rack::Auth::Basic
    attr_accessor :user, :project

    def valid?
      gl = Gitlab.config

      # Authentication with username and password
      login, password = @auth.credentials

      self.user = User.find_by_email(login) || User.find_by_username(login)
      self.user = nil unless user.try(:valid_password?, password)

      # Check user against LDAP backend if user is not authenticated
      # Only check with valid login and password to prevent anonymous bind results
      if user.nil? && gl.ldap.enabled && !login.blank? && !password.blank?
        require "omniauth-ldap"
        ldap = OmniAuth::LDAP::Adaptor.new(gl.ldap)
        ldap_user = ldap.bind_as(
          filter: Net::LDAP::Filter.eq(ldap.uid, login),
          size: 1,
          password: password
        )

        if ldap_user
          self.user = User.find_by_extern_uid_and_provider(ldap_user.dn, 'ldap')
        end
      end

      return false unless user

      # Set GL_USER env variable
      ENV['GL_USER'] = user.email
      # Pass Gitolite update hook
      ENV['GL_BYPASS_UPDATE_HOOK'] = "true"

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
