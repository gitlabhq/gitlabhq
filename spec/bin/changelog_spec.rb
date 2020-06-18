# frozen_string_literal: true

require 'spec_helper'

load File.expand_path('../../bin/changelog', __dir__)

RSpec.describe 'bin/changelog' do
  let(:options) { OpenStruct.new(title: 'Test title', type: 'fixed', dry_run: true) }

  describe ChangelogEntry do
    it 'truncates the file path' do
      entry = described_class.new(options)

      allow(entry).to receive(:ee?).and_return(false)
      allow(entry).to receive(:branch_name).and_return('long-branch-' * 100)

      file_path = entry.send(:file_path)
      expect(file_path.length).to eq(99)
    end
  end

  describe ChangelogOptionParser do
    describe '.parse' do
      it 'parses --amend' do
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

      it 'parses --type and -t' do
        %w[--type -t].each do |flag|
          options = described_class.parse(%W[foo #{flag} security])

          expect(options.type).to eq 'security'
        end
      end

      it 'parses --ee and -e' do
        %w[--ee -e].each do |flag|
          options = described_class.parse(%W[foo #{flag} security])

          expect(options.ee).to eq true
        end
      end

      it 'parses -h' do
        expect do
          expect { described_class.parse(%w[foo -h bar]) }.to output.to_stdout
        end.to raise_error(ChangelogHelpers::Done)
      end

      it 'assigns title' do
        options = described_class.parse(%W[foo -m 1 bar\n baz\r\n --amend])

        expect(options.title).to eq 'foo bar baz'
      end
    end

    describe '.read_type' do
      let(:type) { '1' }

      it 'reads type from $stdin' do
        expect($stdin).to receive(:getc).and_return(type)
        expect do
          expect(described_class.read_type).to eq('added')
        end.to output.to_stdout
      end

      context 'invalid type given' do
        let(:type) { '99' }

        it 'shows error message and exits the program' do
          allow($stdin).to receive(:getc).and_return(type)

          expect do
            expect { described_class.read_type }.to raise_error(
              ChangelogHelpers::Abort,
              'Invalid category index, please select an index between 1 and 8'
            )
          end.to output.to_stdout
        end
      end
    end
  end
end
