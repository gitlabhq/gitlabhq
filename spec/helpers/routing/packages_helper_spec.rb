# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Routing::PackagesHelper do
  describe '#package_path' do
    let(:package) { build_stubbed(:package) }

    it "creates package's path" do
      expect(helper.package_path(package)).to eq("/#{package.project.full_path}/-/packages/#{package.id}")
    end
  end
end
