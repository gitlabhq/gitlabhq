# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::BaseCloudEvent, feature_category: :code_suggestions do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  describe 'event_category' do
    it 'is merge_requests' do
      expect(described_class.get_event_category).to eq(:merge_requests)
    end
  end

  describe 'event_type' do
    it 'raises NotImplementedError when not set by a subclass' do
      expect { described_class.get_event_type }.to raise_error(NotImplementedError)
    end
  end

  describe '#data_schema' do
    context 'with an anonymous subclass using only base fields' do
      let(:subclass) do
        Class.new(described_class) do
          event_type :test_event
        end
      end

      let(:cloud_event_data) do
        {
          specversion: '1.0',
          type: 'com.gitlab.merge_requests.test_event',
          dataschema: 'https://gitlab.com/schemas/merge_requests/test_event/v1.0',
          id: SecureRandom.uuid,
          datacontenttype: 'application/json',
          time: Time.current.iso8601,
          source: "projects/#{merge_request.project.id}",
          subject: "merge_requests/#{merge_request.id}",
          gitlab_user_id: user.id,
          gitlab_user_username: user.username,
          gitlab_organization_id: merge_request.project.organization.id
        }
      end

      let(:valid_data) do
        {
          merge_request_id: merge_request.id,
          merge_request_iid: merge_request.iid,
          project_id: merge_request.project_id
        }
      end

      it 'accepts valid base fields' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data)) }.not_to raise_error
      end

      it 'rejects missing merge_request_id' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:merge_request_id))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects missing merge_request_iid' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:merge_request_iid))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects missing project_id' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:project_id))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects invalid types' do
        expect do
          subclass.new(data: cloud_event_data.merge(data: valid_data.merge(merge_request_id: 'not_an_integer')))
        end
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end
    end

    context 'with an anonymous subclass that adds additional properties' do
      let(:subclass) do
        Class.new(described_class) do
          event_type :random_merge_request_event

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
          type: 'com.gitlab.merge_requests.extended_test',
          dataschema: 'https://gitlab.com/schemas/merge_requests/extended_test/v1.0',
          id: SecureRandom.uuid,
          datacontenttype: 'application/json',
          time: Time.current.iso8601,
          source: "projects/#{merge_request.project.id}",
          subject: "merge_requests/#{merge_request.id}",
          gitlab_user_id: user.id,
          gitlab_user_username: user.username,
          gitlab_organization_id: merge_request.project.organization.id
        }
      end

      let(:base_data) do
        {
          merge_request_id: merge_request.id,
          merge_request_iid: merge_request.iid,
          project_id: merge_request.project_id
        }
      end

      it 'accepts base fields plus the additional field' do
        data = base_data.merge(extra_field: 'approved_at')
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

    it 'each subclass has event_category :merge_requests' do
      described_class.descendants.each do |subclass|
        expect(subclass.get_event_category).to eq(:merge_requests),
          "#{subclass.name} should inherit event_category :merge_requests"
      end
    end
  end
end
