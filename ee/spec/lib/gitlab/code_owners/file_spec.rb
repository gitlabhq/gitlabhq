# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeOwners::File do
  include FakeBlobHelpers

  let(:project) { build(:project) }
  let(:file_content) do
    File.read(Rails.root.join('ee', 'spec', 'fixtures', 'codeowners_example'))
  end

  let(:blob) { fake_blob(path: 'CODEOWNERS', data: file_content) }

  subject(:file) { described_class.new(blob) }

  describe '#parsed_data' do
    it 'parses all the required lines' do
      expected_patterns = [
        '*', '**#file_with_pound.rb', '*.rb', '**CODEOWNERS', '**LICENSE', 'docs/',
        'docs/*', 'config/', '**lib/', '**path with spaces/'
      ]
      expect(file.parsed_data.keys)
        .to contain_exactly(*expected_patterns)
    end

    it 'allows usernames and emails' do
      expect(file.parsed_data['**LICENSE']).to include('legal', 'janedoe@gitlab.com')
    end

    context 'when there are entries that do not look like user references' do
      let(:file_content) do
        "a-path/ this is all random @username and email@gitlab.org"
      end

      it 'ignores the entries' do
        expect(file.parsed_data['**a-path/']).to include('username', 'email@gitlab.org')
      end
    end
  end

  describe '#empty?' do
    subject { file.empty? }

    it { is_expected.to be(false) }

    context 'when there is no content' do
      let(:file_content) { "" }

      it { is_expected.to be(true) }
    end

    context 'when the file is binary' do
      let(:blob) { fake_blob(binary: true) }

      it { is_expected.to be(true) }
    end

    context 'when the file did not exist' do
      let(:blob) { nil }

      it { is_expected.to be(true) }
    end
  end

  describe '#owners_for_path' do
    context 'for a path without matches' do
      let(:file_content) do
        <<~CONTENT
        # Simulating a CODOWNERS without entries
        CONTENT
      end

      it 'returns an nil for an unmatched path' do
        owners = file.owners_for_path('no_matches')

        expect(owners).to be_nil
      end
    end

    it 'matches random files to a pattern' do
      owners = file.owners_for_path('app/assets/something.vue')

      expect(owners).to include('default-codeowner')
    end

    it 'uses the last pattern if multiple patterns match' do
      owners = file.owners_for_path('hello.rb')

      expect(owners).to eq('@ruby-owner')
    end

    it 'returns the usernames for a file matching a pattern with a glob' do
      owners = file.owners_for_path('app/models/repository.rb')

      expect(owners).to eq('@ruby-owner')
    end

    it 'allows specifying multiple users' do
      owners = file.owners_for_path('CODEOWNERS')

      expect(owners).to include('multiple', 'owners', 'tab-separated')
    end

    it 'returns emails and usernames for a matched pattern' do
      owners = file.owners_for_path('LICENSE')

      expect(owners).to include('legal', 'janedoe@gitlab.com')
    end

    it 'allows escaping the pound sign used for comments' do
      owners = file.owners_for_path('examples/#file_with_pound.rb')

      expect(owners).to include('owner-file-with-pound')
    end

    it 'returns the usernames for a file nested in a directory' do
      owners = file.owners_for_path('docs/projects/index.md')

      expect(owners).to include('all-docs')
    end

    it 'returns the usernames for a pattern matched with a glob in a folder' do
      owners = file.owners_for_path('docs/index.md')

      expect(owners).to include('root-docs')
    end

    it 'allows matching files nested anywhere in the repository', :aggregate_failures do
      lib_owners = file.owners_for_path('lib/gitlab/git/repository.rb')
      other_lib_owners = file.owners_for_path('ee/lib/gitlab/git/repository.rb')

      expect(lib_owners).to include('lib-owner')
      expect(other_lib_owners).to include('lib-owner')
    end

    it 'allows allows limiting the matching files to the root of the repository', :aggregate_failures do
      config_owners = file.owners_for_path('config/database.yml')
      other_config_owners = file.owners_for_path('other/config/database.yml')

      expect(config_owners).to include('config-owner')
      expect(other_config_owners).to eq('@default-codeowner')
    end

    it 'correctly matches paths with spaces' do
      owners = file.owners_for_path('path with spaces/README.md')

      expect(owners).to eq('@space-owner')
    end

    context 'paths with whitespaces and username lookalikes' do
      let(:file_content) do
        'a/weird\ path\ with/\ @username\ /\ and-email@lookalikes.com\ / @user-1 email@gitlab.org @user-2'
      end

      it 'parses correctly' do
        owners = file.owners_for_path('a/weird path with/ @username / and-email@lookalikes.com /test.rb')

        expect(owners).to include('user-1', 'user-2', 'email@gitlab.org')
        expect(owners).not_to include('username', 'and-email@lookalikes.com')
      end
    end
  end
end
