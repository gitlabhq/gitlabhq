# frozen_string_literal: true

module ActionDispatchRoutingRedirectPatch
  def build_response(req)
    response = super

    uri = response.headers['Location'].to_s
    body = %(<html><body>You are being <a href="#{ERB::Util.unwrapped_html_escape(uri)}">redirected</a>.</body></html>)

    response.body = body
    response.headers["Content-Length"] = body.length.to_s

    response
  end
end

module ActionControllerRedirectingPatch
  def redirect_to(*, **)
    super

    uri = ERB::Util.unwrapped_html_escape(response.location)
    self.response_body = "<html><body>You are being <a href=\"#{uri}\">redirected</a>.</body></html>"
  end
end

ActionController::Redirecting.prepend(ActionControllerRedirectingPatch)
ActionDispatch::Routing::Redirect.prepend(ActionDispatchRoutingRedirectPatch)
