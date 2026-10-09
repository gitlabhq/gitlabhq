# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::DestroyedCloudEvent, feature_category: :user_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  describe '.build' do
    let(:source) { project }
    let(:current_user) { user }
    let(:member_user_id) { 42 }

    let(:event) do
      described_class.build(
        source: source,
        current_user: current_user,
        user_id: member_user_id,
        root_namespace_id: group.id
      )
    end

    it_behaves_like 'a member base cloud event'

    it 'sets event_type to :destroyed' do
      expect(event.event_type).to eq(:destroyed)
    end

    it 'includes the destroyed member and root namespace in event data' do
      expect(event.event_data).to include(
        root_namespace_id: group.id,
        user_id: member_user_id
      )
    end

    context 'when source is a group' do
      let(:source) { group }

      it_behaves_like 'a member base cloud event'
    end

    context 'when there is no acting user' do
      let(:current_user) { nil }

      it 'publishes without an actor rather than misattributing it' do
        expect(event.data[:gitlab_user_id]).to be_nil
        expect(event.data[:gitlab_user_username]).to be_nil
      end
    end
  end

  describe '#schema' do
    let(:cloud_event_data) do
      {
        specversion: '1.0',
        type: 'com.gitlab.members.destroyed',
        dataschema: 'https://gitlab.com/schemas/members/destroyed/v1.0',
        id: SecureRandom.uuid,
        datacontenttype: 'application/json',
        time: Time.current.iso8601,
        source: "projects/#{project.id}",
        subject: "members/project/#{project.id}",
        gitlab_user_id: user.id,
        gitlab_user_username: user.username,
        gitlab_organization_id: project.organization.id
      }
    end

    it 'accepts an event without root_namespace_id' do
      data = { source_id: project.id, source_type: 'Project', user_id: user.id }

      expect { described_class.new(data: cloud_event_data.merge(data: data)) }.not_to raise_error
    end

    it 'accepts a null user_id' do
      data = { source_id: project.id, source_type: 'Project', user_id: nil }

      expect { described_class.new(data: cloud_event_data.merge(data: data)) }.not_to raise_error
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      source_id: 1,
      source_type: 'Project',
      root_namespace_id: 2,
      user_id: 3
    },
    missing_required: %i[source_id source_type user_id],
    invalid_types: {
      source_id: 'not_an_integer',
      source_type: 123,
      root_namespace_id: 'not_an_integer',
      user_id: 'not_an_integer'
    }
end
