# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::BaseEvent, feature_category: :code_suggestions do
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item) }

  describe 'event_category' do
    it 'is work_items' do
      expect(described_class.get_event_category).to eq(:work_items)
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
          type: 'com.gitlab.work_items.test_event',
          dataschema: 'https://gitlab.com/schemas/work_items/test_event/v1.0',
          id: SecureRandom.uuid,
          datacontenttype: 'application/json',
          time: Time.current.iso8601,
          source: "projects/#{work_item.project.id}",
          subject: "work_items/#{work_item.id}",
          gitlab_user_id: user.id,
          gitlab_user_username: user.username,
          gitlab_organization_id: work_item.project.organization.id
        }
      end

      let(:valid_data) do
        {
          work_item_id: work_item.id,
          work_item_iid: work_item.iid,
          namespace_id: work_item.namespace_id,
          project_id: work_item.project_id,
          work_item_type: work_item.work_item_type.base_type,
          confidential: false
        }
      end

      it 'accepts valid base fields' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data)) }.not_to raise_error
      end

      it 'rejects missing work_item_id' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:work_item_id))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects missing work_item_iid' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:work_item_iid))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects missing namespace_id' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:namespace_id))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects missing work_item_type' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:work_item_type))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects missing confidential' do
        expect { subclass.new(data: cloud_event_data.merge(data: valid_data.except(:confidential))) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end

      it 'rejects invalid types' do
        expect do
          subclass.new(data: cloud_event_data.merge(data: valid_data.merge(work_item_id: 'not_an_integer')))
        end
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end
    end

    context 'with an anonymous subclass that adds additional properties' do
      let(:subclass) do
        Class.new(described_class) do
          event_type :extended_work_item_event

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
          type: 'com.gitlab.work_items.extended_test',
          dataschema: 'https://gitlab.com/schemas/work_items/extended_test/v1.0',
          id: SecureRandom.uuid,
          datacontenttype: 'application/json',
          time: Time.current.iso8601,
          source: "projects/#{work_item.project.id}",
          subject: "work_items/#{work_item.id}",
          gitlab_user_id: user.id,
          gitlab_user_username: user.username,
          gitlab_organization_id: work_item.project.organization.id
        }
      end

      let(:base_data) do
        {
          work_item_id: work_item.id,
          work_item_iid: work_item.iid,
          namespace_id: work_item.namespace_id,
          project_id: work_item.project_id,
          work_item_type: work_item.work_item_type.base_type,
          confidential: false
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

    it 'each subclass has event_category :work_items' do
      described_class.descendants.each do |subclass|
        expect(subclass.get_event_category).to eq(:work_items),
          "#{subclass.name} should inherit event_category :work_items"
      end
    end
  end
end
