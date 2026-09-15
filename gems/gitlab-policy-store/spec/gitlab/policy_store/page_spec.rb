# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Page do
  let(:items) { %w[a b] }
  let(:page) { described_class.new(items: items, per_page: 2, has_next_page: false) }

  describe "#==" do
    it "compares equal to an array holding the same items" do
      expect(page).to eq(items)
    end

    it "compares equal to another Page holding the same items" do
      other = described_class.new(items: items, per_page: 1, has_next_page: true)

      expect(page).to eq(other)
    end

    it "compares unequal to another Page holding different items" do
      other = described_class.new(items: %w[c], per_page: 2, has_next_page: false)

      expect(page).not_to eq(other)
    end
  end

  describe "#each" do
    it "yields the items in order" do
      expect { |block| page.each(&block) }.to yield_successive_args("a", "b")
    end
  end
end
