# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::UpgradePath, feature_category: :shared do
  let(:current_version) { Gitlab::VersionInfo.parse("17.6.1") }
  let(:path) { [] }

  let(:upgrade_path) { described_class.new(path, current_version) }

  shared_examples 'last and next required stops' do
    it 'returns 17.5 for last_required_stop' do
      expect(upgrade_path.last_required_stop).to eq(Gitlab::VersionInfo.new(17, 5))
    end

    it 'returns 17.8 for next_required_stop' do
      expect(upgrade_path.next_required_stop).to eq(Gitlab::VersionInfo.new(17, 8))
    end

    it 'returns false for required_stop?' do
      expect(upgrade_path.required_stop?).to be_falsey
    end
  end

  describe 'out of order versions' do
    it_behaves_like 'last and next required stops' do
      let(:path) do
        [
          { "major" => 16, "minor" => 7 },
          { "major" => 17, "minor" => 5 },
          { "major" => 16, "minor" => 11 },
          { "major" => 17, "minor" => 8 }
        ]
      end
    end
  end

  describe 'uses default for next required stop' do
    it_behaves_like 'last and next required stops' do
      let(:path) do
        [
          { "major" => 16, "minor" => 7 },
          { "major" => 16, "minor" => 11 },
          { "major" => 17, "minor" => 5 }
        ]
      end
    end
  end

  describe 'uses default for previous required stop' do
    it_behaves_like 'last and next required stops' do
      let(:path) do
        [
          { "major" => 16, "minor" => 7 },
          { "major" => 16, "minor" => 11 },
          { "major" => 17, "minor" => 8 }
        ]
      end
    end
  end

  describe 'uses defaults for previous and next required stops' do
    it_behaves_like 'last and next required stops' do
      let(:path) do
        [
          { "major" => 16, "minor" => 7 },
          { "major" => 16, "minor" => 11 }
        ]
      end
    end
  end

  describe 'when the version is a required stop' do
    let(:path) do
      [
        { "major" => 16, "minor" => 7 },
        { "major" => 16, "minor" => 11 },
        { "major" => 17, "minor" => 3 },
        { "major" => 17, "minor" => 5 },
        { "major" => 17, "minor" => 6 },
        { "major" => 17, "minor" => 8 },
        { "major" => 17, "minor" => 11 }
      ]
    end

    it 'returns the current version for next required stop' do
      expect(upgrade_path.next_required_stop).to eq(Gitlab::VersionInfo.new(17, 6))
    end

    it 'returns 17.5 for the previous required stop' do
      expect(upgrade_path.last_required_stop).to eq(Gitlab::VersionInfo.new(17, 5))
    end

    it 'returns true for required_stop?' do
      expect(upgrade_path.required_stop?).to be_truthy
    end
  end
end
