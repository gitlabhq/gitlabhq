# frozen_string_literal: true

module QA
  RSpec.describe 'Framework sanity', :sanity_feature_flags do
    describe 'Feature flag handler checks' do
      context 'with an existing feature flag definition file' do
        let(:definition) do
          path = Pathname.new('../config/feature_flags')
            .expand_path(Runtime::Path.qa_root)
            .glob('**/*.yml')
            .first
          YAML.safe_load(File.read(path))
        end

        it 'reads the correct default enabled state' do
          # This test will fail if we ever remove all the feature flags, but that's very unlikely given how many there
          # are and how much we rely on them.
          expect(QA::Runtime::Feature.enabled?(definition['name'])).to be definition['default_enabled']
        end
      end

      describe 'feature flag definition files' do
        let(:file) do
          path = Pathname.new("#{root}/config/feature_flags/development").expand_path(Runtime::Path.qa_root)
          path.mkpath
          Tempfile.new(%w[ff-test .yml], path)
        end

        let(:flag) { Pathname.new(file.path).basename('.yml').to_s }
        let(:root) { '..' }

        before do
          definition = <<~YAML
          name: #{flag}
          type: development
          default_enabled: #{flag_enabled}
          YAML
          File.write(file, definition)
        end

        after do
          file.close!
        end

        shared_examples 'gets flag value' do
          context 'with a default disabled feature flag' do
            let(:flag_enabled) { 'false' }

            it 'reads the flag as disabled' do
              expect(QA::Runtime::Feature.enabled?(flag)).to be false
            end

            it 'reads as enabled after the flag is enabled' do
              QA::Runtime::Feature.enable(flag)

              expect { QA::Runtime::Feature.enabled?(flag) }.to eventually_be_truthy
                                                                  .within(max_duration: 60, sleep_interval: 5)
            end
          end

          context 'with a default enabled feature flag' do
            let(:flag_enabled) { 'true' }

            it 'reads the flag as enabled' do
              expect(QA::Runtime::Feature.enabled?(flag)).to be true
            end

            it 'reads as disabled after the flag is disabled' do
              QA::Runtime::Feature.disable(flag)

              expect { QA::Runtime::Feature.enabled?(flag) }.to eventually_be_falsey
                                                                  .within(max_duration: 60, sleep_interval: 5)
            end
          end
        end

        context 'with a CE feature flag' do
          include_examples 'gets flag value'
        end

        context 'with an EE feature flag' do
          let(:root) { '../ee' }

          include_examples 'gets flag value'
        end
      end
    end
  end
end
