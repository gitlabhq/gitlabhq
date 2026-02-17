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
    it 'clears the cache when reset is called' do
      record.static_item_id = 1
      record.static_item # cache the value
      expect(TestStaticModel).to receive(:find).once.and_call_original
      record.reset
      record.static_item # should refetch the object
    end

    it 'returns self' do
      expect(record.reset).to eq(record)
    end

    it 'preserves the original reset behavior' do
      record.instance_variable_set(:@static_item, 'original_value')
      record.reset
      expect(record.instance_variable_get(:@static_item)).to be_nil
    end

    context 'when original #reset is not defined' do
      before do
        stub_const('TestRecordWithoutReset', Class.new do
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

          belongs_to_fixed_items :static_item, fixed_items_class: TestStaticModel
        end)
      end

      subject(:record) { TestRecordWithoutReset.new }

      it 'does not raise an error when reset is called' do
        expect { record.reset }.not_to raise_error
      end

      it 'still clears the cache' do
        record.static_item_id = 1
        record.static_item # cache the value
        expect(TestStaticModel).to receive(:find).once.and_call_original
        record.reset
        record.static_item # should refetch the object
      end

      it 'returns self' do
        expect(record.reset).to eq(record)
      end
    end

    context 'when reset is defined in another module included later' do
      before do
        stub_const('AnotherModule', Module.new do
          def reset
            @another_variable = nil
            self
          end
        end)

        stub_const('TestRecordWithLaterModule', Class.new do
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

          belongs_to_fixed_items :static_item, fixed_items_class: TestStaticModel

          # Include another module AFTER belongs_to_fixed_items is called
          include AnotherModule
        end)
      end

      subject(:record) { TestRecordWithLaterModule.new }

      it 'calls reset from all modules in the chain' do
        record.instance_variable_set(:@another_variable, 'value')
        record.static_item_id = 1
        record.static_item # cache the value

        record.reset

        # Cache should be cleared
        expect(TestStaticModel).to receive(:find).once.and_call_original
        record.static_item

        # Another module's reset should also have been called
        expect(record.instance_variable_get(:@another_variable)).to be_nil
      end

      it 'returns self' do
        expect(record.reset).to eq(record)
      end
    end

    context 'when reset is defined in another module included before' do
      before do
        stub_const('EarlierModule', Module.new do
          def reset
            @earlier_variable = nil
            self
          end
        end)

        stub_const('TestRecordWithEarlierModule', Class.new do
          include ActiveModel::Attributes
          # Include another module BEFORE belongs_to_fixed_items is called
          include EarlierModule
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

          belongs_to_fixed_items :static_item, fixed_items_class: TestStaticModel
        end)
      end

      subject(:record) { TestRecordWithEarlierModule.new }

      it 'calls reset from all modules in the chain' do
        record.instance_variable_set(:@earlier_variable, 'value')
        record.static_item_id = 1
        record.static_item # cache the value

        record.reset

        # Cache should be cleared
        expect(TestStaticModel).to receive(:find).once.and_call_original
        record.static_item

        # Earlier module's reset should also have been called
        expect(record.instance_variable_get(:@earlier_variable)).to be_nil
      end

      it 'returns self' do
        expect(record.reset).to eq(record)
      end
    end

    context 'when multiple associations are defined' do
      before do
        stub_const('AnotherStaticModel', Class.new do
          include ActiveRecord::FixedItemsModel::Model

          attribute :description, :string
        end)

        stub_const('AnotherStaticModel::ITEMS', [
          { id: 10, description: 'Description 10' },
          { id: 20, description: 'Description 20' }
        ].freeze)

        stub_const('TestRecordMultiple', Class.new do
          include ActiveModel::Attributes
          include ActiveRecord::FixedItemsModel::HasOne

          attribute :static_item_id, :integer
          attribute :another_item_id, :integer

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

          def reset
            @custom_state = nil
            self
          end

          belongs_to_fixed_items :static_item, fixed_items_class: TestStaticModel
          belongs_to_fixed_items :another_item, fixed_items_class: AnotherStaticModel
        end)
      end

      subject(:record) { TestRecordMultiple.new }

      it 'clears all cached associations on reset' do
        record.static_item_id = 1
        record.another_item_id = 10

        # Cache both associations
        record.static_item
        record.another_item

        # Reset should clear both caches
        record.reset

        expect(TestStaticModel).to receive(:find).once.and_call_original
        expect(AnotherStaticModel).to receive(:find).once.and_call_original

        record.static_item
        record.another_item
      end

      it 'preserves original reset behavior' do
        record.instance_variable_set(:@custom_state, 'value')
        record.reset
        expect(record.instance_variable_get(:@custom_state)).to be_nil
      end

      it 'returns self' do
        expect(record.reset).to eq(record)
      end
    end

    context 'when reset is called with arguments' do
      before do
        stub_const('TestRecordWithResetArgs', Class.new do
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

          def reset(*args)
            @reset_args = args
            self
          end

          belongs_to_fixed_items :static_item, fixed_items_class: TestStaticModel
        end)
      end

      subject(:record) { TestRecordWithResetArgs.new }

      it 'passes arguments through to the original reset method' do
        record.static_item_id = 1
        record.static_item

        record.reset(:foo, :bar)

        expect(record.instance_variable_get(:@reset_args)).to eq([:foo, :bar])
      end

      it 'still clears the cache' do
        record.static_item_id = 1
        record.static_item

        expect(TestStaticModel).to receive(:find).once.and_call_original
        record.reset(:foo)
        record.static_item
      end
    end
  end
end
