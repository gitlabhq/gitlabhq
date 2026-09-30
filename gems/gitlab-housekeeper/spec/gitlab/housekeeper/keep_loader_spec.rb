# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/keep_loader'

RSpec.describe ::Gitlab::Housekeeper::KeepLoader do
  let(:fake_keep) { Class.new(::Gitlab::Housekeeper::Keep) }
  let(:loader) { described_class.new(requested: requested) }

  before do
    allow(loader).to receive(:require)
    allow(Dir).to receive(:glob).with('keeps/*.rb').and_return(['keeps/fake_keep.rb'])
  end

  context 'when a keep is requested by name' do
    let(:requested) { ['Keeps::FakeKeep'] }

    before do
      stub_const('Keeps::FakeKeep', fake_keep)
    end

    it 'loads every keep and returns the requested one' do
      expect(loader).to receive(:require).with(a_string_ending_with('keeps/fake_keep.rb'))

      expect(loader.keeps).to eq([fake_keep])
    end
  end

  context 'when a keep is requested as a class' do
    let(:requested) { [fake_keep] }

    it 'returns it without constantizing' do
      expect(loader.keeps).to eq([fake_keep])
    end
  end

  context 'when no keeps are requested' do
    let(:requested) { nil }

    it 'returns every loaded keep' do
      already_loaded_keep = fake_keep

      expect(loader.keeps).to include(already_loaded_keep)
    end
  end
end
