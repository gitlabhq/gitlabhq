# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Utils::Tar do
  subject(:tar) { described_class.new }

  describe '#version' do
    it 'returns a tar version' do
      expect(tar.version).to match(/tar \(GNU tar\) \d+\.\d+/)
    end
  end
end
