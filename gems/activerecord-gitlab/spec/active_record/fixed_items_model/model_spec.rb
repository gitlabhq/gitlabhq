# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::FixedItemsModel::Model, feature_category: :shared do
  before do
    stub_const('TestStaticModel', Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveRecord::FixedItemsModel::Model

      attribute :id, :integer
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

    it 'returns nil for non-existent id' do
      expect(TestStaticModel.find(999)).to be_nil
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
  end

  describe '.find_by' do
    it 'returns the first item matching the conditions' do
      item = TestStaticModel.find_by(category: :a)
      expect(item.id).to eq(1)
    end

    it 'returns nil when no items match' do
      expect(TestStaticModel.find_by(category: :c)).to be_nil
    end
  end

  describe 'cache isolation' do
    it 'creates new cache instances for each subclass' do
      # Create a subclass of TestModelA
      subclass = Class.new(TestStaticModel)

      # Modifying the subclass cache shouldn't affect the parent class data
      # rubocop:disable GitlabSecurity/PublicSend -- Just used for mocking
      subclass.send(:find_instances)[2] = 'test'
      expect(subclass.send(:find_instances)[2]).to eq('test')
      expect(TestStaticModel.send(:find_instances)[2]).to be_nil
      # rubocop:enable GitlabSecurity/PublicSend
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
end
