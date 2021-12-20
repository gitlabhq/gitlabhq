# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobsHelper do
  describe 'jobs data' do
    let(:project)  { create(:project, :repository) }
    let(:bridge) { create(:ci_bridge, status: :pending) }

    subject(:bridge_data) { helper.bridge_data(bridge) }

    before do
      allow(helper)
        .to receive(:image_path)
        .and_return('/path/to/illustration')
    end

    it 'returns bridge data' do
      expect(bridge_data).to eq({
        "build_name" =>  bridge.name,
        "empty-state-illustration-path" => '/path/to/illustration'
      })
    end
  end
end
