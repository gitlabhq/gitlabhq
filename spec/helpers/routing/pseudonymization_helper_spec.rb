# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Routing::PseudonymizationHelper, feature_category: :product_analytics do
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

  describe '#masked_referrer_url' do
    let(:original_url) { "http://localhost/#{project.full_path}/-/issues/123" }
    let(:masked_url) { 'http://localhost/namespace/project/-/issues/123' }

    it 'masks sensitive parameters in the URL' do
      expect(helper.masked_referrer_url(original_url)).to eq(masked_url)
    end

    context 'when an error occurs' do
      before do
        allow(Rails.application.routes).to receive(:recognize_path)
          .with(original_url)
          .and_raise(ActionController::RoutingError, 'Some routing error')
        allow(helper).to receive(:request).and_return(
          double(
            :Request,
            original_url: original_url,
            original_fullpath: '/dashboard/issues?assignee_username=root'
          )
        )
      end

      it 'calls error tracking and returns nil' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            ActionController::RoutingError,
            url: '/dashboard/issues?assignee_username=root'
          ).and_call_original
        expect(helper.masked_referrer_url(original_url)).to be_nil
      end
    end

    context 'with controller for projects' do
      let(:original_url) { "http://localhost/#{project.full_path}" }
      let(:masked_url) { 'http://localhost/namespace/project' }

      it 'masks sensitive parameters in the URL for projects controller' do
        expect(helper.masked_referrer_url(original_url)).to eq(masked_url)
      end
    end

    context 'with controller for projects/issues' do
      let(:original_url) { "http://localhost/#{project.full_path}/-/issues" }
      let(:masked_url) { 'http://localhost/namespace/project/-/issues' }

      it 'masks sensitive parameters in the URL for projects/issues controller' do
        expect(helper.masked_referrer_url(original_url)).to eq(masked_url)
      end
    end

    context 'with group admin page' do
      let(:original_url) { "http://localhost/admin/groups/#{group.full_path}" }
      let(:masked_url) { 'http://localhost/admin/groups/id' }

      it 'masks sensitive parameters in the URL for group admin page' do
        expect(helper.masked_referrer_url(original_url)).to eq(masked_url)
      end
    end
  end

  describe 'masked_query_params' do
    let(:helper) { Class.new { include Routing::PseudonymizationHelper }.new }

    context 'when there are no query parameters' do
      it 'returns nil' do
        uri = URI.parse('https://gitlab.com')
        expect(helper.masked_query_params(uri)).to be_nil
      end
    end

    context 'when there are query parameters to mask' do
      it 'masks the appropriate query parameters' do
        uri = URI.parse('https://gitlab.com?user_id=123&token=abc')
        result = helper.masked_query_params(uri)
        expect(result).to eq({ 'user_id' => ['masked_user_id'], 'token' => ['masked_token'] })
      end
    end

    context 'when there are query parameters that should not be masked' do
      it 'does not mask the excluded query parameters' do
        uri = URI.parse('https://gitlab.com?scope=all&user_id=123')
        result = helper.masked_query_params(uri)
        expect(result).to eq({ 'scope' => ['all'], 'user_id' => ['masked_user_id'] })
      end
    end

    context 'when there are mixed query parameters' do
      it 'masks only the non-excluded query parameters' do
        uri = URI.parse('http://localhost?scope=all&state=opened&user_id=123')
        result = helper.masked_query_params(uri)
        expect(result).to eq({ 'scope' => ['all'], 'state' => ['opened'], 'user_id' => ['masked_user_id'] })
      end
    end
  end
end
