# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Routing::PseudonymizationHelper do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:subproject) { create(:project, group: subgroup) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:subject) { helper.masked_page_url(group: group, project: project) }

  before do
    stub_feature_flags(mask_page_urls: true)
  end

  shared_examples 'masked url' do
    it 'generates masked page url' do
      expect(subject).to eq(masked_url)
    end
  end

  describe 'when url has params to mask' do
    context 'with controller for MR' do
      let(:masked_url) { "http://localhost/namespace#{group.id}/project#{project.id}/-/merge_requests/#{merge_request.id}" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: "projects/merge_requests",
            action: "show",
            namespace_id: group.name,
            project_id: project.name,
            id: merge_request.id.to_s
          },
          protocol: 'http',
          host: 'localhost',
          query_string: ''
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for issue' do
      let(:masked_url) { "http://localhost/namespace#{group.id}/project#{project.id}/-/issues/#{issue.id}" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: "projects/issues",
            action: "show",
            namespace_id: group.name,
            project_id: project.name,
            id: issue.id.to_s
          },
          protocol: 'http',
          host: 'localhost',
          query_string: ''
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for groups with subgroups and project' do
      let(:masked_url) { "http://localhost/namespace#{subgroup.id}/project#{subproject.id}" }
      let(:group) { subgroup }
      let(:project) { subproject }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'projects',
            action: 'show',
            namespace_id: subgroup.name,
            id: subproject.name
          },
          protocol: 'http',
          host: 'localhost',
          query_string: ''
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for groups and subgroups' do
      let(:masked_url) { "http://localhost/groups/namespace#{subgroup.id}/-/shared" }
      let(:group) { subgroup }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'groups',
            action: 'show',
            id: subgroup.name
          },
          protocol: 'http',
          host: 'localhost',
          query_string: ''
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for blob with file path' do
      let(:masked_url) { "http://localhost/namespace#{group.id}/project#{project.id}/-/blob/:repository_path" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'projects/blob',
            action: 'show',
            namespace_id: group.name,
            project_id: project.name,
            id: 'master/README.md'
          },
          protocol: 'http',
          host: 'localhost',
          query_string: ''
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when assignee_username is present' do
      let(:masked_url) { "http://localhost/dashboard/issues?assignee_username=masked_assignee_username" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'dashboard',
            action: 'issues'
          },
          protocol: 'http',
          host: 'localhost',
          query_string: 'assignee_username=root'
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when author_username is present' do
      let(:masked_url) { "http://localhost/dashboard/issues?author_username=masked_author_username&scope=all&state=opened" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'dashboard',
            action: 'issues'
          },
          protocol: 'http',
          host: 'localhost',
          query_string: 'author_username=root&scope=all&state=opened'
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when some query params are not required to be masked' do
      let(:masked_url) { "http://localhost/dashboard/issues?author_username=masked_author_username&scope=all&state=masked_state&tab=2" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'dashboard',
            action: 'issues'
          },
          protocol: 'http',
          host: 'localhost',
          query_string: 'author_username=root&scope=all&state=opened&tab=2'
        )
      end

      before do
        stub_const('Routing::PseudonymizationHelper::MaskHelper::QUERY_PARAMS_TO_NOT_MASK', %w[scope tab].freeze)
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when query string has keys with the same names as path params' do
      let(:masked_url) { "http://localhost/dashboard/issues?action=masked_action&scope=all&state=opened" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'dashboard',
            action: 'issues'
          },
          protocol: 'http',
          host: 'localhost',
          query_string: 'action=foobar&scope=all&state=opened'
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end
  end

  describe 'when url has no params to mask' do
    let(:original_url) { 'http://localhost/-/security/vulnerabilities' }
    let(:request) do
      double(
        :Request,
        path_parameters: {
          controller: 'security/vulnerabilities',
          action: 'index'
        },
        protocol: 'http',
        host: 'localhost',
        query_string: '',
        original_fullpath: '/-/security/vulnerabilities',
        original_url: original_url
      )
    end

    before do
      allow(helper).to receive(:request).and_return(request)
    end

    it 'returns unchanged url' do
      expect(subject).to eq(original_url)
    end
  end

  describe 'when it raises exception' do
    context 'calls error tracking' do
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'dashboard',
            action: 'issues'
          },
          protocol: 'http',
          host: 'localhost',
          query_string: 'assignee_username=root',
          original_fullpath: '/dashboard/issues?assignee_username=root'
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it 'sends error to sentry and returns nil' do
        allow_next_instance_of(Routing::PseudonymizationHelper::MaskHelper) do |mask_helper|
          allow(mask_helper).to receive(:mask_params).and_raise(ActionController::RoutingError, 'Some routing error')
        end

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          ActionController::RoutingError,
          url: '/dashboard/issues?assignee_username=root').and_call_original

        expect(subject).to be_nil
      end
    end
  end

  describe 'when feature flag is disabled' do
    before do
      stub_feature_flags(mask_page_urls: false)
    end

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end
end
