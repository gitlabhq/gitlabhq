# frozen_string_literal: true

RSpec.describe Bitbucket::Representation::Comment do
  describe '#author' do
    it { expect(described_class.new('user' => { 'uuid' => '{123}' }).author).to eq('{123}') }
    it { expect(described_class.new('user' => { 'nickname' => 'Ben' }).author).to be_nil }
    it { expect(described_class.new({}).author).to be_nil }
  end

  describe '#author_nickname' do
    it { expect(described_class.new('user' => { 'nickname' => 'Ben' }).author_nickname).to eq('Ben') }
    it { expect(described_class.new({}).author_nickname).to be_nil }
  end

  describe '#note' do
    it { expect(described_class.new('content' => { 'raw' => 'Text' }).note).to eq('Text') }
    it { expect(described_class.new({}).note).to be_nil }
  end

  describe '#created_at' do
    it { expect(described_class.new('created_on' => Date.new(2024, 1, 1)).created_at).to eq(Date.new(2024, 1, 1)) }
  end

  describe '#updated_at' do
    it { expect(described_class.new('updated_on' => Date.new(2024, 1, 1)).updated_at).to eq(Date.new(2024, 1, 1)) }
    it { expect(described_class.new('created_on' => Date.new(2024, 1, 1)).updated_at).to eq(Date.new(2024, 1, 1)) }
  end
end
