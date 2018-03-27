require 'spec_helper'

shared_examples 'disabled when using an external authorization service' do
  include ExternalAuthorizationServiceHelpers

  it 'works when the feature is not enabled' do
    subject

    expect(response).to be_success
  end

  it 'renders a 404 with a message when the feature is enabled' do
    enable_external_authorization_service_check

    subject

    expect(response).to have_gitlab_http_status(404)
  end
end

shared_examples 'unauthorized when external service denies access' do
  include ExternalAuthorizationServiceHelpers

  it 'allows access when the authorization service allows it' do
    external_service_allow_access(user, project)

    subject

    # Account for redirects after updates
    expect(response.status).to be_between(200, 302)
  end

  it 'allows access when the authorization service denies it' do
    external_service_deny_access(user, project)

    subject

    expect(response).to have_gitlab_http_status(404)
  end
end
