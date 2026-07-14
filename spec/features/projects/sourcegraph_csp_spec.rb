# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sourcegraph Content Security Policy', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

  shared_context 'disable feature' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_enabled).and_return(false)
    end
  end

  it_behaves_like 'setting CSP', 'connect-src' do
    let_it_be(:sourcegraph_url) { 'https://sourcegraph.test' }
    let_it_be(:allowlisted_url) { "#{sourcegraph_url}/.api/" }
    let_it_be(:extended_controller_class) { Projects::BlobController }

    subject do
      visit project_blob_path(project, File.join('master', 'README.md'))

      response_headers['Content-Security-Policy']
    end

    before do
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_url).and_return(sourcegraph_url)
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_enabled).and_return(true)

      sign_in(user)
    end
  end
end
