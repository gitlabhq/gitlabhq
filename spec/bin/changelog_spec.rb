require 'spec_helper'

load File.expand_path('../../bin/changelog', __dir__)

describe 'bin/changelog' do
  describe ChangelogOptionParser do
    it 'parses --ammend' do
      options = described_class.parse(%w[foo bar --amend])

      expect(options.amend).to eq true
    end

    it 'parses --force and -f' do
      %w[--force -f].each do |flag|
        options = described_class.parse(%W[foo #{flag} bar])

        expect(options.force).to eq true
      end
    end

    it 'parses --merge-request and -m' do
      %w[--merge-request -m].each do |flag|
        options = described_class.parse(%W[foo #{flag} 1234 bar])

        expect(options.merge_request).to eq 1234
      end
    end

    it 'parses --dry-run and -n' do
      %w[--dry-run -n].each do |flag|
        options = described_class.parse(%W[foo #{flag} bar])

        expect(options.dry_run).to eq true
      end
    end

    it 'parses --git-username and -u' do
      allow(described_class).to receive(:git_user_name).and_return('Jane Doe')

      %w[--git-username -u].each do |flag|
        options = described_class.parse(%W[foo #{flag} bar])

        expect(options.author).to eq 'Jane Doe'
      end
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
