# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/shell'

RSpec.describe ::Gitlab::Housekeeper::Shell do
  describe '.execute' do
    it 'delegates to popen3 and returns stdout' do
      expect(Open3).to receive(:popen3).with('echo', 'hello world')
        .and_call_original

      expect(described_class.execute('echo', 'hello world')).to eq("hello world\n")
    end

    it 'raises when result is not successful' do
      expect do
        described_class.execute('cat', 'definitelynotafile')
      end.to raise_error(
        described_class::Error,
        a_string_matching("cat: definitelynotafile: No such file or directory\n")
      )
    end
  end
end
