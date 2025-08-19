# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::FixedItemsModel::HasOne, feature_category: :shared do
  before do
    stub_const('TestStaticModel', Class.new do
      include ActiveRecord::FixedItemsModel::Model

      attribute :name, :string
    end)

    stub_const('TestStaticModel::ITEMS', [
      { id: 1, name: 'Item 1' },
      { id: 2, name: 'Item 2' },
      { id: 3, name: 'Item 3' }
    ].freeze)

    stub_const('TestRecord', Class.new do
      include ActiveModel::Attributes
      include ActiveRecord::FixedItemsModel::HasOne

      attribute :static_item_id, :integer

      # Mock AR methods
      def read_attribute(attr_name)
        send(attr_name)
      end

      def write_attribute(attr_name, value)
        send("#{attr_name}=", value)
      end

      def attribute_present?(attr_name)
        send(attr_name).present?
      end

      # Mock reset method
      def reset
        @static_item = nil
        self
      end

      belongs_to_fixed_items :static_item, fixed_items_class: TestStaticModel
    end)
  end

  subject(:record) { TestRecord.new }

  describe '#belongs_to_fixed_items' do
    it { is_expected.to respond_to(:static_item) }
    it { is_expected.to respond_to(:static_item=) }
    it { is_expected.to respond_to(:static_item?) }

    context 'when foreign key attribute does not exist' do
      before do
        stub_const('TestRecord', Class.new do
          include ActiveModel::Attributes
          include ActiveRecord::FixedItemsModel::HasOne

          attribute :static_item_id, :integer

          # No need for mock methods because they're not called
          # because of the guard raise

          belongs_to_fixed_items :doesnt_exist, fixed_items_class: TestStaticModel
        end)
      end

      it 'getter raises runtime error' do
        expect do
          record.doesnt_exist
        end.to raise_error(RuntimeError, "Missing attribute doesnt_exist_id")
      end

      it 'setter raises runtime error' do
        expect do
          record.doesnt_exist = nil
        end.to raise_error(RuntimeError, "Missing attribute doesnt_exist_id")
      end

      it 'query method raises runtime error' do
        expect do
          record.doesnt_exist?
        end.to raise_error(RuntimeError, "Missing attribute doesnt_exist_id")
      end
    end
  end

  describe 'getter method' do
    it 'returns nil when foreign key is nil' do
      expect(record.static_item).to be_nil
    end

    it 'returns the correct static item when foreign key is set' do
      record.static_item_id = 2
      expect(record.static_item.name).to eq('Item 2')
      # Ensure cache is invalidated when id is changed
      record.static_item_id = 3
      expect(record.static_item.name).to eq('Item 3')
    end

    it 'caches the result' do
      record.static_item_id = 1
      expect(TestStaticModel).to receive(:find).once.and_call_original
      2.times { record.static_item }
    end
  end

  describe 'setter method' do
    it 'sets the foreign key when assigning a static item' do
      static_item = TestStaticModel.find(3)
      record.static_item = static_item
      expect(record.static_item_id).to eq(3)
    end

    it 'sets the foreign key to nil when assigning nil' do
      record.static_item_id = 1
      record.static_item = nil
      expect(record.static_item_id).to be_nil
    end

    it 'clears the cache when setting a new value' do
      record.static_item_id = 1
      record.static_item # cache the value
      record.static_item = TestStaticModel.find(2)
      expect(TestStaticModel).to receive(:find).once.and_call_original
      record.static_item # should refetch the object
    end
  end

  describe 'query method' do
    it 'returns true when foreign key is present' do
      record.static_item_id = 1
      expect(record.static_item?).to be true
    end

    it 'returns false when foreign key is nil' do
      record.static_item_id = nil
      expect(record.static_item?).to be false
    end
  end

  describe '#reset' do
    it 'clears the cache when reloading' do
      record.static_item_id = 1
      record.static_item # cache the value
      expect(TestStaticModel).to receive(:find).once.and_call_original
      record.reset
      record.static_item # should refetch the object
    end

    context 'when original #reset is not defined' do
      before do
        stub_const('TestRecord', Class.new do
          include ActiveModel::Attributes
          include ActiveRecord::FixedItemsModel::HasOne

          attribute :static_item_id, :integer

          belongs_to_fixed_items :static_item, fixed_items_class: TestStaticModel
        end)
      end

      it 'does not raise an error' do
        expect { record.reset }.not_to raise_error
      end
    end
  end
end
