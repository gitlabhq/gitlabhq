# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UpgradePath', feature_category: :shared do
  it 'is parsed correctly' do
    upgrade_path = YAML.safe_load_file(Rails.root.join('config/upgrade_path.yml'))

    expect(upgrade_path.first).to eq({ "major" => 8, "minor" => 11 })
    expect(upgrade_path[15]).to eq({ "major" => 14, "minor" => 0,
"comments" => "**Migrations can take a long time!**" })
  end
end
