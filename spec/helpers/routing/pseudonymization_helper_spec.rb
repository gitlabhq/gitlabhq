# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Routing::PseudonymizationHelper do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:subproject) { create(:project, group: subgroup) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    stub_feature_flags(mask_page_urls: true)
    allow(helper).to receive(:group).and_return(group)
    allow(helper).to receive(:project).and_return(project)
  end

  shared_examples 'masked url' do
    it 'generates masked page url' do
      expect(helper.masked_page_url).to eq(masked_url)
    end
  end

  describe 'when url has params to mask' do
    context 'with controller for MR' do
      let(:masked_url) { "http://test.host/namespace:#{group.id}/project:#{project.id}/-/merge_requests/#{merge_request.id}" }

      before do
        allow(Rails.application.routes).to receive(:recognize_path).and_return({
         controller: "projects/merge_requests",
         action: "show",
         namespace_id: group.name,
         project_id: project.name,
         id: merge_request.id.to_s
        })
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for issue' do
      let(:masked_url) { "http://test.host/namespace:#{group.id}/project:#{project.id}/-/issues/#{issue.id}" }

      before do
        allow(Rails.application.routes).to receive(:recognize_path).and_return({
         controller: "projects/issues",
         action: "show",
         namespace_id: group.name,
         project_id: project.name,
         id: issue.id.to_s
        })
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for groups with subgroups and project' do
      let(:masked_url) { "http://test.host/namespace:#{subgroup.id}/project:#{subproject.id}"}

      before do
        allow(helper).to receive(:group).and_return(subgroup)
        allow(helper).to receive(:project).and_return(subproject)
        allow(Rails.application.routes).to receive(:recognize_path).and_return({
          controller: 'projects',
          action: 'show',
          namespace_id: subgroup.name,
          id: subproject.name
        })
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for groups and subgroups' do
      let(:masked_url) { "http://test.host/namespace:#{subgroup.id}"}

      before do
        allow(helper).to receive(:group).and_return(subgroup)
        allow(Rails.application.routes).to receive(:recognize_path).and_return({
          controller: 'groups',
          action: 'show',
          id: subgroup.name
        })
      end

      it_behaves_like 'masked url'
    end

    context 'with controller for blob with file path' do
      let(:masked_url) { "http://test.host/namespace:#{group.id}/project:#{project.id}/-/blob/:repository_path" }

      before do
        allow(Rails.application.routes).to receive(:recognize_path).and_return({
          controller: 'projects/blob',
          action: 'show',
          namespace_id: group.name,
          project_id: project.name,
          id: 'master/README.md'
        })
      end

      it_behaves_like 'masked url'
    end

    context 'with non identifiable controller' do
      let(:masked_url) { "http://test.host/dashboard/issues?assignee_username=root" }

      before do
        controller.request.path = '/dashboard/issues'
        controller.request.query_string = 'assignee_username=root'
        allow(Rails.application.routes).to receive(:recognize_path).and_return({
          controller: 'dashboard',
          action: 'issues'
        })
      end

      it_behaves_like 'masked url'
    end
  end

  describe 'when url has no params to mask' do
    let(:root_url) { 'http://test.host' }

    context 'returns root url' do
      it 'masked_page_url' do
        expect(helper.masked_page_url).to eq(root_url)
      end
    end
  end

  describe 'when it raises exception' do
    context 'calls error tracking' do
      before do
        controller.request.path = '/dashboard/issues'
        controller.request.query_string = 'assignee_username=root'
        allow(Rails.application.routes).to receive(:recognize_path).and_return({
          controller: 'dashboard',
          action: 'issues'
        })
      end

      it 'sends error to sentry and returns nil' do
        allow(helper).to receive(:mask_params).with(anything).and_raise(ActionController::RoutingError, 'Some routing error')

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          ActionController::RoutingError,
          url: '/dashboard/issues?assignee_username=root').and_call_original

        expect(helper.masked_page_url).to be_nil
      end
    end
  end

  describe 'when feature flag is disabled' do
    before do
      stub_feature_flags(mask_page_urls: false)
    end

    it 'returns nil' do
      expect(helper.masked_page_url).to be_nil
    end
  end
end
