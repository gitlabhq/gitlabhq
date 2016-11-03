require 'spec_helper'

load File.expand_path('../../bin/changelog', __dir__)

describe 'bin/changelog' do
  describe ChangelogOptionParser do
    it 'parses --ammend' do
      options = described_class.parse(%w[foo bar --amend])

      expect(options.amend).to eq true
    end

    it 'parses --force' do
      options = described_class.parse(%w[foo --force bar])

      expect(options.force).to eq true
    end

    it 'parses -f' do
      options = described_class.parse(%w[foo -f bar])

      expect(options.force).to eq true
    end

    it 'parses --merge-request' do
      options = described_class.parse(%w[foo --merge-request 1234 bar])

      expect(options.merge_request).to eq 1234
    end

    it 'parses -m' do
      options = described_class.parse(%w[foo -m 4321 bar])

      expect(options.merge_request).to eq 4321
    end

    it 'parses --dry-run' do
      options = described_class.parse(%w[foo --dry-run bar])

      expect(options.dry_run).to eq true
    end

    it 'parses -n' do
      options = described_class.parse(%w[foo -n bar])

      expect(options.dry_run).to eq true
    end

    it 'parses --git-username' do
      allow(described_class).to receive(:git_user_name).and_return('Jane Doe')
      options = described_class.parse(%w[foo --git-username bar])

      expect(options.author).to eq 'Jane Doe'
    end

    it 'parses -u' do
      allow(described_class).to receive(:git_user_name).and_return('John Smith')
      options = described_class.parse(%w[foo -u bar])

      expect(options.author).to eq 'John Smith'
    end

    it 'parses -h' do
      expect do
        $stdout = StringIO.new

        described_class.parse(%w[foo -h bar])
      end.to raise_error(SystemExit)
    end

    it 'assigns title' do
      options = described_class.parse(%W[foo -m 1 bar\n -u baz\r\n --amend])

      expect(options.title).to eq 'foo bar baz'
    end
  end
end
