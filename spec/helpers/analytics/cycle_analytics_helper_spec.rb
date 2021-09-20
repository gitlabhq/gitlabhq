# frozen_string_literal: true
require "spec_helper"

RSpec.describe Analytics::CycleAnalyticsHelper do
  describe '#cycle_analytics_initial_data' do
    let(:user) { create(:user, name: 'fake user', username: 'fake_user') }
    let(:image_path_keys) { [:empty_state_svg_path, :no_data_svg_path, :no_access_svg_path] }
    let(:api_path_keys) { [:milestones_path, :labels_path] }
    let(:additional_data_keys) { [:full_path, :group_id, :group_path, :project_id, :request_path] }
    let(:group) { create(:group) }

    subject(:cycle_analytics_data) { helper.cycle_analytics_initial_data(project, group) }

    before do
      project.add_maintainer(user)
    end

    context 'when a group is present' do
      let(:project) { create(:project, group: group) }

      it "sets the correct data keys" do
        expect(cycle_analytics_data.keys)
          .to match_array(api_path_keys + image_path_keys + additional_data_keys)
      end

      it "sets group paths" do
        expect(cycle_analytics_data)
          .to include({
            full_path: project.full_path,
            group_path: "/#{project.namespace.name}",
            group_id: project.namespace.id,
            request_path: "/#{project.full_path}/-/value_stream_analytics",
            milestones_path: "/groups/#{group.name}/-/milestones.json",
            labels_path: "/groups/#{group.name}/-/labels.json"
          })
      end
    end

    context 'when a group is not present' do
      let(:group) { nil }
      let(:project) { create(:project) }

      it "sets the correct data keys" do
        expect(cycle_analytics_data.keys)
          .to match_array(image_path_keys + api_path_keys + additional_data_keys)
      end

      it "sets project name space paths" do
        expect(cycle_analytics_data)
          .to include({
            full_path: project.full_path,
            group_path: project.namespace.path,
            group_id: project.namespace.id,
            request_path: "/#{project.full_path}/-/value_stream_analytics",
            milestones_path: "/#{project.full_path}/-/milestones.json",
            labels_path: "/#{project.full_path}/-/labels.json"
          })
      end
    end
  end
end
