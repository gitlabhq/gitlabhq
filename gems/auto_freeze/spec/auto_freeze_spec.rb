# frozen_string_literal: true

RSpec.describe AutoFreeze do
  describe '::VERSION' do
    it 'is a non-nil string' do
      expect(described_class::VERSION).to be_a(String)
    end
  end

  describe '::GemError' do
    it 'is a subclass of StandardError' do
      expect(described_class::GemError.ancestors).to include(StandardError)
    end
  end

  describe 'integration test' do
    after do
      RequireHooks.class_variable_set(:@@around_load, []) # rubocop:disable Style/ClassVars
    end

    it 'works with included_gems' do
      described_class.setup!(included_gems: %w[language_server-protocol])

      require 'language_server-protocol'

      expect(LanguageServer::Protocol::VERSION).to be_frozen
    end

    it 'works with excluded_gems' do
      described_class.setup!(excluded_gems: %w[minitest])

      require 'minitest'

      expect(Minitest::VERSION).not_to be_frozen
    end

    it 'works with excluded_gems of dependencies' do
      # Exclude some dependencies of pry-shell
      described_class.setup!(excluded_gems: %w[tty-markdown unicode_utils])

      require 'pry-shell'

      # unicode_utils-1.4.0/lib/unicode_utils/read_cdata.rb:124:in `force_encoding'
      # does not work with frozen strings
      expect(UnicodeUtils::CDATA_DIR).not_to be_frozen
    end
  end

  describe '.setup!' do
    before do
      allow(Freezolite).to receive(:setup)
    end

    context 'when included_gems is empty (default)' do
      let(:gem_paths) { %w[/usr/local/bundle /home/user/.gem] }

      before do
        allow(Gem).to receive(:path).and_return(gem_paths)
      end

      it 'calls Freezolite.setup with patterns covering all gem paths' do
        described_class.setup!

        expect(Freezolite).to have_received(:setup).with(
          patterns: [
            '/usr/local/bundle/*.rb',
            '/home/user/.gem/*.rb'
          ],
          exclude_patterns: []
        )
      end

      context 'with excluded_gems' do
        let(:noko_spec) { instance_double(Gem::Specification, full_name: 'nokogiri-1.16.0') }
        let(:as_spec)   { instance_double(Gem::Specification, full_name: 'activesupport-7.1.0') }

        before do
          allow(Gem::Specification).to receive(:find_by_name).with('nokogiri').and_return(noko_spec)
          allow(Gem::Specification).to receive(:find_by_name).with('activesupport').and_return(as_spec)
        end

        it 'resolves each excluded gem by name and builds a glob using its full versioned name' do
          described_class.setup!(excluded_gems: %w[nokogiri activesupport])

          expect(Freezolite).to have_received(:setup).with(
            patterns: [
              '/usr/local/bundle/*.rb',
              '/home/user/.gem/*.rb'
            ],
            exclude_patterns: [
              '**/nokogiri-1.16.0/**',
              '**/activesupport-7.1.0/**'
            ]
          )
        end
      end

      context 'with no excluded_gems' do
        it 'calls Freezolite.setup with empty exclude_patterns' do
          described_class.setup!(excluded_gems: [])

          expect(Freezolite).to have_received(:setup).with(
            patterns: [
              '/usr/local/bundle/*.rb',
              '/home/user/.gem/*.rb'
            ],
            exclude_patterns: []
          )
        end
      end

      context 'when an excluded gem is not installed' do
        it 'raises GemError' do
          expect { described_class.setup!(excluded_gems: %w[this_gem_does_not_exist]) }
            .to raise_error(described_class::GemError)
        end
      end
    end

    context 'when included_gems is not empty' do
      let(:require_paths) { %w[/usr/local/bundle/gems/activesupport-7.0.0/lib] }
      let(:gem_spec) { instance_double(Gem::Specification, full_require_paths: require_paths) }

      before do
        allow(Gem::Specification).to receive(:find_by_name).and_return(gem_spec)
      end

      it 'looks up each gem by short name' do
        described_class.setup!(included_gems: %w[activesupport])

        expect(Gem::Specification).to have_received(:find_by_name).with('activesupport')
      end

      it 'calls Freezolite.setup with require path patterns for the included gems' do
        described_class.setup!(included_gems: %w[activesupport])

        expect(Freezolite).to have_received(:setup).with(
          patterns: %w[/usr/local/bundle/gems/activesupport-7.0.0/lib/*.rb],
          exclude_patterns: []
        )
      end

      it 'raises an ArgumentError when used with excluded_gems' do
        expect { described_class.setup!(included_gems: %w[activesupport], excluded_gems: %w[nokogiri]) }
          .to raise_error(ArgumentError, 'Cannot use both included_gems: and excluded_gems: arguments')
      end

      context 'when a gem has multiple require paths' do
        let(:require_paths) { %w[/bundle/gems/nokogiri-1.0/lib /bundle/gems/nokogiri-1.0/ext] }

        it 'includes a pattern for every require path' do
          described_class.setup!(included_gems: %w[nokogiri])

          expect(Freezolite).to have_received(:setup).with(
            patterns: [
              '/bundle/gems/nokogiri-1.0/lib/*.rb',
              '/bundle/gems/nokogiri-1.0/ext/*.rb'
            ],
            exclude_patterns: []
          )
        end
      end

      context 'with multiple included gems' do
        let(:as_spec) do
          instance_double(Gem::Specification,
            full_require_paths: %w[/bundle/gems/activesupport-7.0/lib])
        end

        let(:noko_spec) do
          instance_double(Gem::Specification,
            full_require_paths: %w[/bundle/gems/nokogiri-1.0/lib /bundle/gems/nokogiri-1.0/ext])
        end

        before do
          allow(Gem::Specification).to receive(:find_by_name).with('activesupport').and_return(as_spec)
          allow(Gem::Specification).to receive(:find_by_name).with('nokogiri').and_return(noko_spec)
        end

        it 'flattens all require paths from all gems into a single patterns array' do
          described_class.setup!(included_gems: %w[activesupport nokogiri])

          expect(Freezolite).to have_received(:setup).with(
            patterns: [
              '/bundle/gems/activesupport-7.0/lib/*.rb',
              '/bundle/gems/nokogiri-1.0/lib/*.rb',
              '/bundle/gems/nokogiri-1.0/ext/*.rb'
            ],
            exclude_patterns: []
          )
        end
      end

      context 'when a gem is not installed' do
        before do
          allow(Gem::Specification).to receive(:find_by_name).and_call_original
        end

        it 'raises GemError' do
          expect { described_class.setup!(included_gems: %w[this_gem_does_not_exist]) }
            .to raise_error(described_class::GemError)
        end
      end
    end
  end
end
