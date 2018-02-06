require 'spec_helper'

load File.expand_path('../../bin/changelog', __dir__)

describe 'bin/changelog' do
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

      it 'parses -h' do
        expect do
          expect { described_class.parse(%w[foo -h bar]) }.to output.to_stdout
        end.to raise_error(SystemExit)
      end

      it 'assigns title' do
        options = described_class.parse(%W[foo -m 1 bar\n -u baz\r\n --amend])

        expect(options.title).to eq 'foo bar baz'
      end
    end

    describe '.read_type'  do
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
            expect do
              expect { described_class.read_type }.to raise_error(SystemExit)
            end.to output("Invalid category index, please select an index between 1 and 8\n").to_stderr
          end.to output.to_stdout
        end
      end
    end
  end
end
