# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::BaseEvent, feature_category: :user_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'event_category' do
    it 'is members' do
      expect(described_class.get_event_category).to eq(:members)
    end
  end

  describe 'event_type' do
    it 'raises NotImplementedError when not set by a subclass' do
      expect { described_class.get_event_type }.to raise_error(NotImplementedError)
    end
  end

  describe 'data schema validation' do
    context 'with an anonymous subclass using only base fields' do
      let(:subclass) do
        Class.new(described_class) do
          event_type :test_event
        end
      end

      let(:cloud_event_data) do
        {
          specversion: '1.0',
          type: 'com.gitlab.members.test_event',
          dataschema: 'https://gitlab.com/schemas/members/test_event/v1.0',
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

      let(:valid_data) do
        {
          source_id: project.id,
          source_type: 'Project'
        }
      end

      it 'accepts valid base fields' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data)) }.not_to raise_error
      end

      it 'rejects missing source_id' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:source_id))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects missing source_type' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:source_type))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects invalid types' do
        expect do
          subclass.new(data: cloud_event_data.merge(data: valid_data.merge(source_id: 'not_an_integer')))
        end
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end
    end

    context 'with an anonymous subclass that adds additional properties' do
      let(:subclass) do
        Class.new(described_class) do
          event_type :extended_member_event

          private

          def additional_properties
            { 'extra_field' => { 'type' => 'string' } }
          end

          def additional_required
            %w[extra_field]
          end
        end
      end

      let(:cloud_event_data) do
        {
          specversion: '1.0',
          type: 'com.gitlab.members.extended_member_event',
          dataschema: 'https://gitlab.com/schemas/members/extended_member_event/v1.0',
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

      let(:base_data) do
        {
          source_id: project.id,
          source_type: 'Project'
        }
      end

      it 'accepts base fields plus the additional field' do
        data = base_data.merge(extra_field: 'some_value')
        expect { subclass.new(data: cloud_event_data.merge(data: data)) }.not_to raise_error
      end

      it 'rejects when the additional required field is missing' do
        expect { subclass.new(data: cloud_event_data.merge(data: base_data)) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end
    end
  end

  describe 'all subclasses', :eager_load do
    it 'each subclass sets an event_type' do
      described_class.descendants.each do |subclass|
        expect { subclass.get_event_type }.not_to raise_error,
          "#{subclass.name} must call `event_type :some_type`"
      end
    end

    it 'each subclass has event_category :members' do
      described_class.descendants.each do |subclass|
        expect(subclass.get_event_category).to eq(:members),
          "#{subclass.name} should inherit event_category :members"
      end
    end
  end
end
