module Gitlab
  class DeviseFailure < Devise::FailureApp
    protected

    # Override `Devise::FailureApp#request_format` to handle a special case
    #
    # This tells Devise to handle an unauthenticated `.zip` request as an HTML
    # request (i.e., redirect to sign in).
    #
    # Otherwise, Devise would respond with a 401 Unauthorized with
    # `Content-Type: application/zip` and a response body in plaintext, and the
    # browser would freak out.
    #
    # See https://gitlab.com/gitlab-org/gitlab-ce/issues/12944
    def request_format
      if request.format == :zip
        Mime::Type.lookup_by_extension(:html).ref
      else
        super
      end
    end
  end
end
