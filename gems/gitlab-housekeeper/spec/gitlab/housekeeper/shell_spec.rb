# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/shell'

RSpec.describe ::Gitlab::Housekeeper::Shell do
  describe '.execute' do
    it 'delegates to popen3 and returns stdout' do
      expect(Open3).to receive(:popen3).with(ENV.to_h, 'echo', 'hello world')
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

  describe '.rubocop_autocorrect' do
    it 'delegates to #execute and returns true on success' do
      expect(described_class)
        .to receive(:execute)
        .with(
          'rubocop', '--autocorrect', '--force-exclusion', 'foo.rb',
          env: a_hash_including('REVEAL_RUBOCOP_TODO' => nil)
        )
        .and_return('output')

      expect(described_class.rubocop_autocorrect('foo.rb')).to eq(true)
    end

    it 'delegates to #execute and returns false on failure' do
      allow(described_class)
        .to receive(:execute)
        .with(any_args)
        .and_raise(described_class::Error.new)

      expect(described_class.rubocop_autocorrect('foo.rb')).to eq(false)
    end
  end
end
