# frozen_string_literal: true

require 'open3'
require_relative '../../caproni/scripts/seed'

RSpec.describe Seed do
  # CI runs it by absolute path, which is when a seeder loading seed.rb could run it twice
  it 'loads the seeders when run as a script by absolute path' do
    script = File.expand_path('../../caproni/scripts/seed.rb', __dir__)
    _, err, status = Open3.capture3(RbConfig.ruby, script)

    expect(status.exitstatus).to eq(1)
    expect(err).to start_with("Usage: #{script} admin_token|oidc_application")
  end

  describe '.program' do
    let(:first) { Module.new { def self.program_from_env = "first\n" } }
    let(:second) { Module.new { def self.program_from_env = "second\n" } }

    it 'runs the programs of every seeder in order, in one runner program' do
      expect(described_class.program([first, second])).to eq("first\nsecond\n")
    end
  end
end
