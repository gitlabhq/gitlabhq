# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require 'fileutils'
require 'httparty'
require 'readline'

require_relative '../../../../bin/lib/feature_generator/shared'

RSpec.describe FeatureGenerator::Shared, feature_category: :tooling do
  let(:groups) { { geo: { label: 'group::geo' } } }
  let(:groups_json) { groups.to_json }

  before do
    allow(HTTParty)
      .to receive(:get)
        .with(FeatureGenerator::Shared::WWW_GITLAB_COM_GROUPS_JSON, format: :plain)
        .and_return(groups_json)
  end

  describe described_class::OptionParserMixin do
    let(:host) do
      Module.new do
        extend FeatureGenerator::Shared::Helpers
        extend FeatureGenerator::Shared::OptionParserMixin
      end
    end

    describe '#groups' do
      it 'fetches and memoizes the groups JSON' do
        expect(HTTParty).to receive(:get).once.and_return(groups_json)

        2.times { host.groups }
      end

      it 'returns parsed group data' do
        expect(host.groups).to eq({ 'geo' => { 'label' => 'group::geo' } })
      end
    end

    describe '#group_labels' do
      it 'returns sorted label strings' do
        expect(host.group_labels).to eq(['group::geo'])
      end
    end

    describe '#find_group_by_label' do
      it 'returns the group hash when found' do
        expect(host.find_group_by_label('group::geo')).to eq({ 'label' => 'group::geo' })
      end

      it 'returns nil when label is not found' do
        expect(host.find_group_by_label('group::missing')).to be_nil
      end
    end

    describe '#group_list' do
      it 'returns numbered label strings' do
        expect(host.group_list).to eq(['1. group::geo'])
      end
    end

    describe '#read_group' do
      let(:group_prompt) do
        /Specify the group label to which the SaaS feature belongs, from the following list/
      end

      before do
        allow(host).to receive(:fzf_available?).and_return(false)
      end

      context 'when valid group label is given' do
        it 'returns the group and prints confirmation' do
          expect(Readline).to receive(:readline).and_return('group::geo')

          expect { expect(host.read_group(noun: 'SaaS feature')).to eq('group::geo') }
            .to output(group_prompt).to_stdout
        end
      end

      context 'when valid index is given' do
        it 'resolves the label by index' do
          expect(Readline).to receive(:readline).and_return('1')

          expect { expect(host.read_group(noun: 'SaaS feature')).to eq('group::geo') }
            .to output(group_prompt).to_stdout
        end
      end

      context 'when invalid group is given' do
        it 'shows error and retries' do
          expect(Readline).to receive(:readline).and_return('invalid')
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { host.read_group(noun: 'SaaS feature') }.to raise_error(/EOF/)
          end.to output(group_prompt).to_stdout
               .and output(/The group label isn't in the above labels list/).to_stderr
        end
      end

      context 'when invalid index is given' do
        it 'shows error and retries' do
          expect(Readline).to receive(:readline).and_return('99')
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { host.read_group(noun: 'SaaS feature') }.to raise_error(/EOF/)
          end.to output(group_prompt).to_stdout
               .and output(/The group label isn't in the above labels list/).to_stderr
        end
      end

      context 'when noun changes the prompt' do
        it 'uses the provided noun in the prompt' do
          expect(Readline).to receive(:readline).and_return('group::geo')

          expect { host.read_group(noun: 'Dedicated feature') }
            .to output(/Dedicated feature/).to_stdout
        end
      end
    end

    describe '#read_introduced_by_url' do
      it 'includes the noun in the prompt' do
        expect(Readline).to receive(:readline).and_return('')

        expect { host.read_introduced_by_url(noun: 'Dedicated feature') }
          .to output(/Dedicated feature/).to_stdout
      end
    end

    describe '#read_url' do
      context 'with a valid URL' do
        it 'returns the URL' do
          expect(Readline).to receive(:readline).and_return('https://example.com')
          expect(HTTParty).to receive(:head).and_return(instance_double(HTTParty::Response, success?: true))

          expect { expect(host.read_url('Enter URL:')).to eq('https://example.com') }
            .to output(/Enter URL:/).to_stdout
        end
      end

      context 'with an empty URL (skip)' do
        it 'returns nil' do
          expect(Readline).to receive(:readline).and_return('')

          expect { expect(host.read_url('Enter URL:')).to be_nil }
            .to output(/Enter URL:/).to_stdout
        end
      end

      context 'when readline returns nil (Ctrl-D / EOF)' do
        it 'returns nil without raising NoMethodError' do
          expect(Readline).to receive(:readline).and_return(nil)

          expect { expect(host.read_url('Enter URL:')).to be_nil }
            .to output(/Enter URL:/).to_stdout
        end
      end

      context 'with an invalid URL' do
        it 'shows error and retries' do
          expect(Readline).to receive(:readline).and_return('https://bad')
          expect(HTTParty).to receive(:head).and_return(instance_double(HTTParty::Response, success?: false))
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { host.read_url('Enter URL:') }.to raise_error(/EOF/)
          end.to output(/Enter URL:/).to_stdout
               .and output(/isn't valid/).to_stderr
        end
      end

      context 'with a non-https URL' do
        it 'shows error and retries' do
          expect(Readline).to receive(:readline).and_return('http://bad')
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { host.read_url('Enter URL:') }.to raise_error(/EOF/)
          end.to output(/Enter URL:/).to_stdout
               .and output(/URL needs to start with https/).to_stderr
        end
      end
    end

    describe '#valid_url?' do
      context 'with a non-https URL' do
        it 'returns false' do
          expect(host.valid_url?('http://example.com')).to be false
        end
      end

      context 'with a valid https URL' do
        it 'returns true' do
          expect(HTTParty).to receive(:head).and_return(instance_double(HTTParty::Response, success?: true))

          expect(host.valid_url?('https://example.com')).to be true
        end
      end

      context 'with an unreachable https URL' do
        it 'returns false (not nil)' do
          expect(HTTParty).to receive(:head).and_return(instance_double(HTTParty::Response, success?: false))

          expect(host.valid_url?('https://example.com')).to be false
        end
      end
    end

    describe '#read_milestone' do
      it 'reads major.minor from VERSION' do
        allow(File).to receive(:read).with('VERSION').and_return("19.1.0-pre\n")

        expect(host.read_milestone).to eq('19.1')
      end
    end

    describe '#fetch_json' do
      it 'parses the HTTP response as JSON' do
        allow(HTTParty).to receive(:get).and_return('[{"a":1}]')

        expect(host.fetch_json('https://example.com/data.json')).to eq([{ 'a' => 1 }])
      end
    end

    describe '#with_retries' do
      it 'yields and returns the result on success' do
        expect(host.with_retries { 42 }).to eq(42)
      end

      it 'retries on Errno::ECONNRESET and raises after exhaustion' do
        attempts = 0

        expect do
          host.with_retries(attempts: 2) do
            attempts += 1
            raise Errno::ECONNRESET
          end
        end.to raise_error(Errno::ECONNRESET)

        expect(attempts).to eq(2)
      end
    end
  end

  describe described_class::CreatorMixin do
    let(:creator_class) do
      Class.new do
        include FeatureGenerator::Shared::Helpers
        include FeatureGenerator::Shared::CreatorMixin

        attr_reader :options

        def initialize(options)
          @options = options
        end

        def file_path
          'tmp/test_feature.yml'
        end

        def contents
          "---\nname: test\n"
        end
      end
    end

    let(:options) { Struct.new(:name, :amend, keyword_init: true).new(name: 'test_feature', amend: false) }
    let(:creator) { creator_class.new(options) }

    describe '#assert_feature_branch!' do
      it 'raises when on master' do
        allow(creator).to receive(:branch_name).and_return('master')

        expect { creator.assert_feature_branch! }
          .to raise_error(FeatureGenerator::Shared::Abort, /Create a branch first/)
      end

      it 'does not raise on a feature branch' do
        allow(creator).to receive(:branch_name).and_return('my-feature-branch')

        expect { creator.assert_feature_branch! }.not_to raise_error
      end
    end

    describe '#assert_name!' do
      using RSpec::Parameterized::TableSyntax

      where(:name, :should_raise) do
        'valid_name'    | false
        'valid-name'    | false
        'valid123'      | false
        '.invalid'      | true
        'has space'     | true
        'UPPERCASE'     | true
      end

      with_them do
        it 'validates name format' do
          allow(options).to receive(:name).and_return(name)

          if should_raise
            expect { creator.assert_name!(noun: 'SaaS feature') }
              .to raise_error(FeatureGenerator::Shared::Abort, /Provide a name for the SaaS feature/)
          else
            expect { creator.assert_name!(noun: 'SaaS feature') }.not_to raise_error
          end
        end
      end
    end

    describe '#write' do
      it 'writes contents to file_path' do
        expect(FileUtils).to receive(:mkdir_p).with('tmp')
        expect(File).to receive(:write).with('tmp/test_feature.yml', "---\nname: test\n")

        creator.write
      end
    end

    describe '#editor' do
      it 'returns EDITOR env variable' do
        stub_env('EDITOR', 'vim')

        expect(creator.editor).to eq('vim')
      end

      it 'returns nil when EDITOR is unset' do
        stub_env('EDITOR', nil)

        expect(creator.editor).to be_nil
      end
    end
  end
end
