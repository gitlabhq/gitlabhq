# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/filter_identifiers'

RSpec.describe ::Gitlab::Housekeeper::FilterIdentifiers do
  describe '.matches_filters?' do
    let(:identifiers) { %w[this-is a-list of IdentifierS] }

    it 'matches when all regexes match at least one identifier' do
      filter_identifiers = described_class.new([/list/, /Ide.*fier/])
      expect(filter_identifiers.matches_filters?(identifiers)).to eq(true)
    end

    it 'does not match when none of the regexes match' do
      filter_identifiers = described_class.new([/nomatch/, /Ide.*fffffier/])
      expect(filter_identifiers.matches_filters?(identifiers)).to eq(false)
    end

    it 'does not match when only some of the regexes match' do
      filter_identifiers = described_class.new([/nomatch/, /Ide.*fier/])
      expect(filter_identifiers.matches_filters?(identifiers)).to eq(false)
    end

    it 'matches an empty list of filters' do
      filter_identifiers = described_class.new([])
      expect(filter_identifiers.matches_filters?(identifiers)).to eq(true)
    end
  end
end
