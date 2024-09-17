# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Canonical link', feature_category: :workspaces do
  include Features::CanonicalLinkHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, namespace: user.namespace) }
  let_it_be(:issue) { create(:issue, project: project) }

  let_it_be(:issue_request) { issue_url(issue) }
  let_it_be(:project_request) { project_url(project) }

  before do
    sign_in(user)
  end

  shared_examples 'shows canonical link' do
    specify do
      visit request_url

      expect(page).to have_canonical_link(expected_url)
    end
  end

  shared_examples 'does not show canonical link' do
    specify do
      visit request_url

      expect(page).not_to have_any_canonical_links
    end
  end

  it_behaves_like 'does not show canonical link' do
    let(:request_url) { issue_request }
  end

  it_behaves_like 'shows canonical link' do
    let(:request_url) { issue_request + '/' }
    let(:expected_url) { issue_request }
  end

  it_behaves_like 'shows canonical link' do
    let(:request_url) { project_issues_url(project) + "/?state=opened" }
    let(:expected_url) { project_issues_url(project, state: 'opened') }
  end

  it_behaves_like 'does not show canonical link' do
    let(:request_url) { project_request }
  end

  it_behaves_like 'shows canonical link' do
    let(:request_url) { project_request + '/' }
    let(:expected_url) { project_request }
  end

  it_behaves_like 'shows canonical link' do
    let(:query_params) { '?foo=bar' }
    let(:request_url) { project_request + "/#{query_params}" }
    let(:expected_url) { project_request + query_params }
  end

  # Hard-coded canonical links

  it_behaves_like 'shows canonical link' do
    let(:request_url) { explore_root_path }
    let(:expected_url) { explore_projects_url }
  end
end
