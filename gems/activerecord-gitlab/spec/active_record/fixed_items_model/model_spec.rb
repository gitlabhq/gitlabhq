# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::FixedItemsModel::Model, feature_category: :shared do
  before do
    stub_const('TestStaticModel', Class.new do
      include ActiveRecord::FixedItemsModel::Model

      attribute :name, :string
      attribute :category
    end)

    stub_const('TestStaticModel::ITEMS', [
      { id: 1, name: 'Item 1', category: :a },
      { id: 2, name: 'Item 2', category: :b },
      { id: 3, name: 'Item 3', category: :a }
    ].freeze)
  end

  describe '.find' do
    it 'returns the correct item by id' do
      item = TestStaticModel.find(2)
      expect(item.name).to eq('Item 2')
    end

    it 'returns the correct item by id string' do
      item = TestStaticModel.find('2')
      expect(item.name).to eq('Item 2')
    end

    it 'returns error for non-numeric string id' do
      expect { TestStaticModel.find('invalid') }.to raise_error(ActiveRecord::FixedItemsModel::RecordNotFound,
        "Couldn't find TestStaticModel with 'id'=invalid")
    end

    it 'raises error for non-existent id' do
      expect { TestStaticModel.find(999) }.to raise_error(ActiveRecord::FixedItemsModel::RecordNotFound,
        "Couldn't find TestStaticModel with 'id'=999")
    end

    it 'caches the found instance' do
      item1 = TestStaticModel.find(1)
      item2 = TestStaticModel.find(1)
      expect(item1).to be(item2)
    end
  end

  describe '.all' do
    it 'returns all items' do
      expect(TestStaticModel.all.map(&:id)).to eq([1, 2, 3])
    end

    context "when item definition has duplicated ids" do
      before do
        stub_const('TestStaticModel::ITEMS', [
          { id: 1, name: 'Item 1', category: :a },
          { id: 1, name: 'Item 2', category: :b },
          { id: 1, name: 'Item 3', category: :a }
        ].freeze)
      end

      it 'raises an error' do
        expect do
          TestStaticModel.all
        end.to raise_error("Static definition ITEMS has 2 duplicated IDs!")
      end
    end

    context "when item definition is invalid" do
      before do
        stub_const('TestStaticModel::ITEMS', [
          { id: -1, name: 'Item 1', category: :a }
        ].freeze)
      end

      it 'raises an error' do
        expect do
          TestStaticModel.all
        end.to raise_error("Static definition in ITEMS is invalid! Id must be greater than 0")
      end
    end
  end

  describe '.where' do
    it 'returns items matching the conditions' do
      items = TestStaticModel.where(category: :a)
      expect(items.map(&:id)).to eq([1, 3])
    end

    it 'returns empty array when no items match' do
      expect(TestStaticModel.where(category: :c)).to be_empty
    end

    it 'handles multiple conditions' do
      items = TestStaticModel.where(category: :a, name: 'Item 1')
      expect(items.map(&:id)).to eq([1])
    end

    it 'handles array conditions' do
      items = TestStaticModel.where(category: [:a, :b])
      expect(items.map(&:id)).to eq([1, 2, 3])
    end

    it 'raises error for invalid attribute' do
      expect do
        TestStaticModel.where(invalid_column: 1)
      end.to raise_error(ActiveRecord::FixedItemsModel::UnknownAttribute,
        "Unknown attribute 'invalid_column' for TestStaticModel")
    end

    it 'raises error for invalid attribute in multiple conditions' do
      expect do
        TestStaticModel.where(category: :a, invalid_column: 1)
      end.to raise_error(ActiveRecord::FixedItemsModel::UnknownAttribute,
        "Unknown attribute 'invalid_column' for TestStaticModel")
    end
  end

  describe '.find_by' do
    it 'returns the first item matching the conditions' do
      item = TestStaticModel.find_by(category: :a)
      expect(item.id).to eq(1)
    end

    it 'returns nil when no items match' do
      expect(TestStaticModel.find_by(category: :c)).to be_nil
    end

    it 'raises error for invalid attribute' do
      expect do
        TestStaticModel.find_by(invalid_column: 1)
      end.to raise_error(ActiveRecord::FixedItemsModel::UnknownAttribute,
        "Unknown attribute 'invalid_column' for TestStaticModel")
    end
  end

  describe 'storage isolation' do
    let(:subclass) { Class.new(TestStaticModel).tap(&:all) }
    let(:new_item) { subclass.new(id: 2, name: 'foo') }

    it 'creates new storage instance for each subclass' do
      subclass.storage[new_item.id] = new_item

      expect(subclass.find(2)).to eq(new_item)
      expect(TestStaticModel.find(2)).not_to eq(new_item)
    end
  end

  describe '#matches?' do
    let(:item) { TestStaticModel.find(1) }

    it 'returns true when all conditions match' do
      expect(item.matches?(category: :a, name: 'Item 1')).to be true
    end

    it 'returns false when any condition does not match' do
      expect(item.matches?(category: :b, name: 'Item 1')).to be false
    end

    it 'handles array conditions' do
      expect(item.matches?(category: [:a, :b])).to be true
      expect(item.matches?(category: [:b, :c])).to be false
    end

    it 'does not match with unpermitted attribute' do
      expect(item).not_to receive(:doesnt_exist)
      expect(item.matches?(doesnt_exist: 'test', name: 'Item 1')).to be false
    end
  end

  describe '#has_attribute?' do
    let(:item) { TestStaticModel.new(id: 1) }

    it 'returns true for valid attributes' do
      expect(item.has_attribute?(:id)).to be true
    end

    it 'returns false for invalid attributes' do
      expect(item.has_attribute?(:non_existent)).to be false
    end

    it 'handles both symbol and string keys' do
      expect(item.has_attribute?(:id)).to be true
      expect(item.has_attribute?('id')).to be true
    end

    it 'returns false for nil or empty string keys' do
      expect(item.has_attribute?(nil)).to be false
      expect(item.has_attribute?('')).to be false
    end
  end

  describe '#read_attribute' do
    let(:item) { TestStaticModel.new(id: 1, name: 'Test', category: :a) }

    it 'returns the value of a valid attribute' do
      expect(item.read_attribute(:id)).to eq(1)
      expect(item.read_attribute(:name)).to eq('Test')
      expect(item.read_attribute(:category)).to eq(:a)
    end

    it 'returns nil for an invalid attribute' do
      expect(item.read_attribute(:non_existent)).to be_nil
    end

    it 'handles both symbol and string keys' do
      expect(item.read_attribute(:id)).to eq(1)
      expect(item.read_attribute('id')).to eq(1)
    end

    it 'returns nil for nil or empty string keys' do
      expect(item.read_attribute(nil)).to be_nil
      expect(item.read_attribute('')).to be_nil
    end
  end

  describe '#inspect' do
    it 'returns a string representation of the object' do
      item = TestStaticModel.find(1)
      expect(item.inspect).to eq('#<TestStaticModel id: 1, name: "Item 1", category: :a>')
    end
  end

  describe "#==" do
    let(:item) { TestStaticModel.new(id: 1) }

    it "returns true when compared with the same object" do
      expect(item).to eq(TestStaticModel.find(1))
      expect(item).to eq(TestStaticModel.new(id: 1))
      expect(item).to eq(TestStaticModel.all.first)
      expect(item).to eq(TestStaticModel.where(id: 1).first)
      expect(item).to eq(TestStaticModel.find_by(id: 1))
      expect(item).to eq(TestStaticModel.find_by(name: 'Item 1'))
    end

    it "returns false when the objects are not the same" do
      expect(item).not_to eq(TestStaticModel.find(2))
      expect(item).not_to eq(TestStaticModel.new(id: 2))
      expect(item).not_to eq(TestStaticModel.find_by(name: 'Item 2'))
    end

    it 'returns true when comparing same object' do
      model = TestStaticModel.new(id: 1)
      expect(model).to eq(model)
    end

    it 'handles string vs integer ids' do
      model1 = TestStaticModel.new(id: 1)
      model2 = TestStaticModel.new(id: '1')

      # Depends on attribute casting
      expect(model1).to eq(model2) # Both cast to integer
    end

    it "returns false when id is nil" do
      expect(TestStaticModel.new).not_to eq(TestStaticModel.find(1))
    end

    context 'when comparing with different classes' do
      before do
        stub_const('AnotherStaticModel', Class.new do
          include ActiveRecord::FixedItemsModel::Model

          attribute :name, :string
        end)

        stub_const('AnotherStaticModel::ITEMS', [
          { id: 1, name: 'Item 1' },
          { id: 2, name: 'Item 2' }
        ].freeze)
      end

      it 'returns false even with same id' do
        model1 = TestStaticModel.new(id: 1)
        model2 = AnotherStaticModel.new(id: 1)

        expect(model1).not_to eq(model2)
      end
    end
  end

  describe '#hash' do
    it 'returns same hash for instances with same id and class' do
      model1 = TestStaticModel.new(id: 1)
      model2 = TestStaticModel.new(id: 1)

      expect(model1.hash).to eq(model2.hash)
    end

    it 'returns different hash for different ids' do
      model1 = TestStaticModel.new(id: 1)
      model2 = TestStaticModel.new(id: 2)

      expect(model1.hash).not_to eq(model2.hash)
    end

    it 'without id falls back to object hash' do
      model1 = TestStaticModel.new(id: nil)
      model2 = TestStaticModel.new(id: nil)

      expect(model1.hash).not_to eq(model2.hash)
    end
  end

  describe "#hash key lookup" do
    let(:item) { TestStaticModel.new(id: 1) }
    let(:hash) { { item => 'item_hash' } }

    it "returns the value when we look up with the same object" do
      expect(hash[TestStaticModel.find(1)]).to eq('item_hash')
      expect(hash[TestStaticModel.new(id: 1)]).to eq('item_hash')
      expect(hash[TestStaticModel.find_by(id: 1)]).to eq('item_hash')
      expect(hash[TestStaticModel.where(id: 1).first]).to eq('item_hash')
      expect(hash[TestStaticModel.all.first]).to eq('item_hash')
    end

    it "returns nil when the look up objects are not the same" do
      expect(hash[TestStaticModel.find(2)]).to be_nil
      expect(hash[TestStaticModel.new(id: 2)]).to be_nil
      expect(hash[TestStaticModel.find_by(name: 'Item 2')]).to be_nil
    end

    it 'handles nil id instances correctly' do
      model1 = TestStaticModel.new(id: nil)
      model2 = TestStaticModel.new(id: nil)

      hash = { model1 => 'nil_value' }
      expect(hash[model2]).to be_nil # Different objects
      expect(hash[model1]).to eq('nil_value') # Same object
    end
  end

  describe '#validations' do
    it 'validates id numericality' do
      expect(TestStaticModel.new(id: 0)).not_to be_valid
      expect(TestStaticModel.new(id: -1)).not_to be_valid
      expect(TestStaticModel.new(id: 1)).to be_valid
    end
  end

  describe 'Set usage' do
    it 'removes duplicates based on id' do
      model1 = TestStaticModel.new(id: 1)
      model2 = TestStaticModel.new(id: 1)
      model3 = TestStaticModel.new(id: 2)

      set = Set.new([model1, model2, model3])

      expect(set.size).to eq(2)
      expect(set.to_a.map(&:id).sort).to eq([1, 2])
    end
  end

  describe 'Array#uniq' do
    it 'removes duplicates based on id' do
      models = [
        TestStaticModel.new(id: 1),
        TestStaticModel.new(id: 1),
        TestStaticModel.new(id: 2),
        TestStaticModel.new(id: 2),
        TestStaticModel.new(id: 3)
      ]

      unique = models.uniq

      expect(unique.size).to eq(3)
      expect(unique.map(&:id)).to eq([1, 2, 3])
    end
  end
end
