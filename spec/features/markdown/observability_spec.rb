# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Observability rendering', :js, feature_category: :metrics do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:observable_url) { "https://www.gitlab.com/groups/#{group.path}/-/observability/explore?observability_path=/explore?foo=bar" }
  let_it_be(:expected_observable_url) { "https://observe.gitlab.com/-/#{group.id}/explore?foo=bar" }

  before do
    stub_config_setting(url: "https://www.gitlab.com")
    group.add_developer(user)
    sign_in(user)
  end

  context 'when user is a developer of the embedded group' do
    context 'when embedding in an issue' do
      let(:issue) do
        create(:issue, project: project, description: observable_url)
      end

      before do
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      it_behaves_like 'embeds observability'
    end

    context 'when embedding in an MR' do
      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project, description: observable_url)
      end

      before do
        visit merge_request_path(merge_request)
        wait_for_requests
      end

      it_behaves_like 'embeds observability'
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(observability_group_tab: false)
    end

    context 'when embedding in an issue' do
      let(:issue) do
        create(:issue, project: project, description: observable_url)
      end

      before do
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      it_behaves_like 'does not embed observability'
    end

    context 'when embedding in an MR' do
      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project, description: observable_url)
      end

      before do
        visit merge_request_path(merge_request)
        wait_for_requests
      end

      it_behaves_like 'does not embed observability'
    end
  end
end
