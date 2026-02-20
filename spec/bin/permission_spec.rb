# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../lib/authz/validation'

# Suppress output while loading the permission script to avoid printing during file execution
original_stdout = $stdout
original_stderr = $stderr
$stdout = StringIO.new
$stderr = StringIO.new

load File.expand_path('../../bin/permission', __dir__)

$stdout = original_stdout
$stderr = original_stderr

STUB_FEATURE_CATEGORIES = %w[custom_dashboards_foundation permissions continuous_integration].freeze

RSpec.describe 'bin/permission', feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  describe PermissionCreator do
    let(:argv) do
      [
        'create_test_resource', '-a', 'create', '-r', 'test_resource',
        '-c', 'custom_dashboards_foundation', '-d', 'Test description'
      ]
    end

    let(:options) { PermissionOptionParser.parse(argv) }
    let(:creator) { described_class.new(options) }

    def run_creator
      creator.execute
    rescue PermissionHelpers::Done
      nil
    end

    before do
      # Reset memoized values so stubs take effect
      PermissionOptionParser.instance_variable_set(:@feature_categories, nil)

      if PermissionOptionParser.instance_variable_defined?(:@fzf_available)
        PermissionOptionParser.remove_instance_variable(:@fzf_available)
      end

      allow(YAML).to receive(:safe_load_file)
        .with(PermissionOptionParser::FEATURE_CATEGORIES_FILE)
        .and_return(STUB_FEATURE_CATEGORIES)

      # Mock Readline to prevent hanging on input and showing prompts
      allow(Readline).to receive(:readline).and_return('')

      # Mock output methods to suppress all output
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)
      allow($stdout).to receive(:write)
      allow($stderr).to receive(:puts)
      allow($stderr).to receive(:print)

      # ignore writes and default File.exist? to false to avoid filesystem dependency
      allow(File).to receive_messages(write: true, exist?: false)
      allow(FileUtils).to receive(:mkdir_p).and_return(true)

      # disable fzf (prevent actual fzf process from launching)
      allow(PermissionOptionParser).to receive(:find_compatible_command).and_return(nil)
    end

    describe '#execute' do
      context 'when creating permission files' do
        before do
          allow(PermissionOptionParser).to receive_messages(
            read_feature_category: 'custom_dashboards_foundation',
            read_resource_display_name: 'Test Resource',
            read_resource_description: 'Test resource description'
          )
        end

        it 'creates permission file at correct path' do
          expect(File).to receive(:write).with(
            'config/authz/permissions/test_resource/create.yml',
            anything
          )

          expect { run_creator }.not_to raise_error
        end

        it 'creates metadata file when it does not exist' do
          expect(File).to receive(:write).with(
            'config/authz/permissions/test_resource/_metadata.yml',
            anything
          )

          expect { run_creator }.not_to raise_error
        end

        it 'does not create metadata file when it already exists' do
          allow(File).to receive(:exist?).with('config/authz/permissions/test_resource/_metadata.yml')
            .and_return(true)

          expect(File).not_to receive(:write).with(
            'config/authz/permissions/test_resource/_metadata.yml',
            anything
          )

          run_creator
        end

        it 'generates correct YAML content for permission' do
          expect(File).to receive(:write).with(
            anything,
            /name: create_test_resource/
          )

          run_creator
        end

        it 'includes description in permission YAML' do
          expect(File).to receive(:write).with(
            anything,
            /description: Test description/
          )

          run_creator
        end

        it 'includes feature_category in metadata YAML' do
          expect(File).to receive(:write).with(
            anything,
            /feature_category: custom_dashboards_foundation/
          )

          run_creator
        end
      end

      context 'with dry-run option' do
        let(:argv) do
          %w[create_test_resource -a create -r test_resource -c custom_dashboards_foundation --dry-run]
        end

        it 'does not write files' do
          expect(File).not_to receive(:write)

          run_creator
        end

        it 'still runs without error' do
          expect { run_creator }.not_to raise_error
        end
      end

      context 'when permission name is invalid' do
        let(:argv) do
          %w[create.test.resource -a create -r test_resource -c custom_dashboards_foundation]
        end

        it 'raises error when name contains invalid characters' do
          expect { creator.execute }
            .to raise_error(PermissionHelpers::Abort)
        end
      end

      context 'when permission already exists' do
        let(:argv) { %w[create_test_resource -a create -r test_resource -c custom_dashboards_foundation] }

        it 'fails when permission already exists' do
          allow(File).to receive(:exist?).with('config/authz/permissions/test_resource/create.yml')
            .and_return(true)

          expect { creator.execute }.to raise_error(PermissionHelpers::Abort, /already exists/)
        end

        it 'overwrites when --force is used' do
          allow(File).to receive(:exist?).with('config/authz/permissions/test_resource/create.yml')
            .and_return(true)
          argv << '--force'

          expect(File).to receive(:write).with(
            'config/authz/permissions/test_resource/create.yml',
            anything
          )

          expect { run_creator }.not_to raise_error
        end
      end

      context 'when action is disallowed' do
        let(:argv) do
          %w[admin_test_resource -a admin -r test_resource -c custom_dashboards_foundation]
        end

        it 'fails with error for disallowed actions' do
          expect { creator.execute }
            .to raise_error(PermissionHelpers::Abort, /Action 'admin' is not allowed/)
        end

        where(:action, :suggestion) do
          Authz::Validation::DISALLOWED_ACTIONS.map { |k, v| [k.to_s, v] }
        end

        with_them do
          let(:argv) do
            [
              "#{action}_test_resource",
              '-a', action, '-r', 'test_resource',
              '-c', 'custom_dashboards_foundation'
            ]
          end

          it 'fails with suggestion to use allowed action' do
            expect { creator.execute }
              .to raise_error(PermissionHelpers::Abort, /Use '#{Regexp.escape(suggestion)}'/)
          end
        end
      end

      context 'when extracting suggestions from permission name' do
        let(:argv) { %w[create_test_resource] }

        before do
          allow(PermissionOptionParser).to receive_messages(
            read_feature_category: 'custom_dashboards_foundation',
            read_description: 'Test description',
            read_resource_display_name: 'Test Resource',
            read_resource_description: 'Test resource description'
          )
        end

        it 'prompts for action with suggestion from name' do
          expect(PermissionOptionParser).to receive(:read_action)
            .with(suggestion: 'create').and_return('create')

          run_creator
        end

        it 'prompts for resource with suggestion from name' do
          expect(PermissionOptionParser).to receive(:read_resource)
            .with(suggestion: 'test_resource').and_return('test_resource')

          run_creator
        end

        it 'prompts for description' do
          expect(PermissionOptionParser).to receive(:read_description)

          run_creator
        end

        it 'prompts for feature category' do
          expect(PermissionOptionParser).to receive(:read_feature_category)

          run_creator
        end
      end

      context 'when no permission name provided' do
        let(:argv) { [] }

        before do
          allow(PermissionOptionParser).to receive_messages(
            read_action: 'create',
            read_resource: 'test_resource',
            read_feature_category: 'custom_dashboards_foundation',
            read_description: 'Test description',
            read_resource_display_name: 'Test Resource',
            read_resource_description: 'Test resource description'
          )
        end

        it 'prompts for action, resource, and description' do
          expect(PermissionOptionParser).to receive(:read_action)
          expect(PermissionOptionParser).to receive(:read_resource)
          expect(PermissionOptionParser).to receive(:read_description)

          run_creator
        end

        it 'prompts for feature category' do
          expect(PermissionOptionParser).to receive(:read_feature_category)

          run_creator
        end
      end

      context 'when creating metadata file' do
        let(:argv) { %w[create_test_resource] }

        before do
          allow(PermissionOptionParser).to receive_messages(
            read_feature_category: 'custom_dashboards_foundation',
            read_description: 'Test description',
            read_resource_display_name: 'Test Resource',
            read_resource_description: 'Test resource description'
          )
        end

        it 'prompts for resource display name when creating metadata' do
          expect(PermissionOptionParser).to receive(:read_resource_display_name)

          run_creator
        end

        it 'prompts for resource description when creating metadata' do
          expect(PermissionOptionParser).to receive(:read_resource_description)

          run_creator
        end

        it 'does not prompt for metadata when file exists' do
          allow(File).to receive(:exist?).with('config/authz/permissions/test_resource/_metadata.yml')
            .and_return(true)

          expect(PermissionOptionParser).not_to receive(:read_feature_category)
          expect(PermissionOptionParser).not_to receive(:read_resource_display_name)
          expect(PermissionOptionParser).not_to receive(:read_resource_description)

          run_creator
        end
      end

      context 'when all required fields are provided via CLI' do
        let(:argv) do
          [
            'create_test_resource', '-a', 'create', '-r', 'test_resource',
            '-c', 'custom_dashboards_foundation', '-d', 'Test description'
          ]
        end

        it 'does not prompt for any field' do
          expect(PermissionOptionParser).not_to receive(:read_action)
          expect(PermissionOptionParser).not_to receive(:read_resource)
          expect(PermissionOptionParser).not_to receive(:read_description)
          expect(PermissionOptionParser).not_to receive(:read_feature_category)
          expect(PermissionOptionParser).not_to receive(:read_resource_display_name)
          expect(PermissionOptionParser).not_to receive(:read_resource_description)

          run_creator
        end

        it 'includes optional metadata fields when passed via CLI' do
          argv.push('--resource-display-name', 'Test Resource', '--resource-description', 'A test resource')

          expect(File).to receive(:write).with(
            'config/authz/permissions/test_resource/_metadata.yml',
            /name: Test Resource/
          )

          run_creator
        end
      end

      context 'when action and resource provided via CLI but not feature category' do
        let(:argv) { %w[create_test_resource -a create -r test_resource] }

        before do
          allow(PermissionOptionParser).to receive_messages(
            read_feature_category: 'custom_dashboards_foundation',
            read_resource_display_name: 'Test Resource',
            read_resource_description: 'Test resource description'
          )
        end

        it 'auto-defaults description and prompts for feature category and optional metadata' do
          expect(PermissionOptionParser).not_to receive(:read_description)
          expect(PermissionOptionParser).to receive(:read_feature_category)
          expect(PermissionOptionParser).to receive(:read_resource_display_name)
          expect(PermissionOptionParser).to receive(:read_resource_description)

          run_creator
        end
      end
    end
  end

  describe PermissionOptionParser do
    before do
      # Reset memoized values so stubs take effect
      described_class.instance_variable_set(:@feature_categories, nil)

      if described_class.instance_variable_defined?(:@fzf_available)
        described_class.remove_instance_variable(:@fzf_available)
      end

      allow(YAML).to receive(:safe_load_file)
        .with(described_class::FEATURE_CATEGORIES_FILE)
        .and_return(STUB_FEATURE_CATEGORIES)

      # Mock Readline to prevent hanging on input and showing prompts
      allow(Readline).to receive(:readline).and_return('')

      # Mock output methods to suppress all output
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)
      allow($stdout).to receive(:write)
      allow($stderr).to receive(:puts)
      allow($stderr).to receive(:print)

      # disable fzf for all tests
      allow(described_class).to receive(:find_compatible_command).and_return(nil)
    end

    describe '.parse' do
      where(:param, :argv, :result) do
        :name             | %w[create_test_resource] | 'create_test_resource'
        :force            | %w[create_test_resource -f] | true
        :force            | %w[create_test_resource --force] | true
        :dry_run          | %w[create_test_resource -n] | true
        :dry_run          | %w[create_test_resource --dry-run] | true
        :action           | %w[create_test_resource -a create] | 'create'
        :action           | %w[create_test_resource --action read] | 'read'
        :resource         | %w[create_test_resource -r test_resource] | 'test_resource'
        :resource         | %w[create_test_resource --resource custom_dashboard] | 'custom_dashboard'
        :feature_category | %w[create_test_resource -c custom_dashboards_foundation] | 'custom_dashboards_foundation'
        :feature_category | %w[create_test_resource --feature-category permissions] | 'permissions'
        :description              | ['create_test_resource', '-d', 'Test'] | 'Test'
        :description              | ['create_test_resource', '--description', 'My'] | 'My'
        :resource_display_name    | ['create_test_resource', '--resource-display-name', 'Test'] | 'Test'
        :resource_description     | ['create_test_resource', '--resource-description', 'Desc'] | 'Desc'
      end

      with_them do
        it 'parses the argument correctly' do
          options = described_class.parse(Array(argv))

          expect(options.public_send(param)).to eq(result)
        end
      end

      it 'parses -h help flag' do
        expect { described_class.parse(%w[--help]) }.to raise_error(PermissionHelpers::Done)
      end

      it 'raises error for invalid feature category' do
        expect { described_class.parse(%w[create_test_resource -c invalid_category]) }
          .to raise_error(PermissionHelpers::Abort, /\e\[31merror\e\[0m Unknown feature category 'invalid_category'/)
      end

      it 'accepts valid feature category' do
        options = described_class.parse(%w[create_test_resource -c custom_dashboards_foundation])
        expect(options.feature_category).to eq('custom_dashboards_foundation')
      end
    end

    describe '.read_action' do
      context 'when valid action is given' do
        it 'reads action from stdin' do
          allow(Readline).to receive(:readline).and_return('create')
          result = described_class.read_action
          expect(result).to eq('create')
        end
      end

      context 'when action index is given' do
        it 'picks action by index' do
          allow(Readline).to receive(:readline).and_return('1')
          result = described_class.read_action
          expect(result).to eq('create')
        end
      end

      context 'when invalid action is given' do
        it 'shows error message and retries' do
          call_count = 0
          allow(Readline).to receive(:readline) do
            call_count += 1
            call_count == 1 ? '' : 'create'
          end

          expect(described_class).to receive(:warn_with).with(/Invalid action specified/)
          result = described_class.read_action
          expect(result).to eq('create')
        end
      end

      context 'when disallowed action is given' do
        it 'shows error and retries' do
          allow(Readline).to receive(:readline).and_return('admin', 'create')

          expect(described_class).to receive(:warn_with).with(/Action 'admin' is not allowed/)
          result = described_class.read_action
          expect(result).to eq('create')
        end
      end

      context 'when custom action is given by selecting "other"' do
        it 'prompts for custom action name' do
          other_index = PermissionOptionParser::COMMON_ACTIONS.keys.index('other') + 1
          allow(Readline).to receive(:readline).and_return(other_index.to_s, 'custom_action')

          result = described_class.read_action
          expect(result).to eq('custom_action')
        end
      end

      context 'when custom action is given directly' do
        it 'accepts custom action without selection' do
          allow(Readline).to receive(:readline).and_return('custom_action')

          result = described_class.read_action
          expect(result).to eq('custom_action')
        end
      end

      context 'when action has a suggestion' do
        it 'shows suggestion in prompt' do
          allow(Readline).to receive(:readline).and_return('')

          result = described_class.read_action(suggestion: 'create')
          expect(result).to eq('create')
        end
      end
    end

    describe '.read_resource' do
      context 'when valid resource is given' do
        it 'reads resource from stdin' do
          allow(Readline).to receive(:readline).and_return('test_resource')

          result = described_class.read_resource
          expect(result).to eq('test_resource')
        end
      end

      context 'when resource with hyphens is given' do
        it 'converts hyphens to underscores' do
          allow(Readline).to receive(:readline).and_return('test-resource')

          result = described_class.read_resource
          expect(result).to eq('test_resource')
        end
      end

      context 'when invalid resource is given' do
        it 'shows warning message and retries' do
          call_count = 0
          allow(Readline).to receive(:readline) do
            call_count += 1
            call_count == 1 ? 'INVALID!' : 'valid_resource'
          end

          expect(described_class).to receive(:warn_with).with(/Invalid resource/)
          result = described_class.read_resource
          expect(result).to eq('valid_resource')
        end
      end

      context 'when resource ends with underscore' do
        it 'shows warning message and retries' do
          call_count = 0
          allow(Readline).to receive(:readline) do
            call_count += 1
            call_count == 1 ? 'test_' : 'test_resource'
          end

          expect(described_class).to receive(:warn_with).with(/Invalid resource/)
          result = described_class.read_resource
          expect(result).to eq('test_resource')
        end
      end

      context 'when resource has a suggestion' do
        it 'shows suggestion in prompt' do
          allow(Readline).to receive(:readline).and_return('')

          result = described_class.read_resource(suggestion: 'test_resource')
          expect(result).to eq('test_resource')
        end
      end
    end

    describe '.read_feature_category' do
      context 'when valid category is given' do
        it 'reads category from stdin' do
          allow(Readline).to receive(:readline).and_return('custom_dashboards_foundation')

          result = described_class.read_feature_category
          expect(result).to eq('custom_dashboards_foundation')
        end
      end

      context 'when category index is given' do
        it 'picks category by index' do
          allow(Readline).to receive(:readline).and_return('1')

          result = described_class.read_feature_category
          expect(result).to eq(STUB_FEATURE_CATEGORIES.first)
        end
      end

      context 'when invalid category is given' do
        it 'shows warning message and retries' do
          call_count = 0
          allow(Readline).to receive(:readline) do
            call_count += 1
            call_count == 1 ? 'invalid_category' : 'custom_dashboards_foundation'
          end

          expect(described_class).to receive(:warn_with).with(/Invalid category specified/)
          result = described_class.read_feature_category
          expect(result).to eq('custom_dashboards_foundation')
        end
      end
    end

    describe '.read_description' do
      context 'when description is given' do
        it 'reads description from stdin' do
          allow(Readline).to receive(:readline).and_return('Test description')

          result = described_class.read_description(action: 'create', resource: 'test_resource')
          expect(result).to eq('Test description')
        end
      end

      context 'when empty description is given' do
        it 'returns suggestion' do
          allow(Readline).to receive(:readline).and_return('')

          result = described_class.read_description(action: 'create', resource: 'test_resource')
          expect(result).to eq('Grants the ability to create test resources')
        end
      end

      context 'when description has a suggestion' do
        it 'shows suggestion in prompt' do
          allow(Readline).to receive(:readline).and_return('')

          result = described_class.read_description(action: 'create', resource: 'test_resource')
          expect(result).to include('Grants the ability to')
        end
      end
    end

    describe '.read_resource_display_name' do
      context 'when display name is given' do
        it 'reads display name from stdin' do
          allow(Readline).to receive(:readline).and_return('Custom Dashboard')

          result = described_class.read_resource_display_name(resource: 'custom_dashboard')
          expect(result).to eq('Custom Dashboard')
        end
      end

      context 'when empty display name is given' do
        it 'returns nil' do
          allow(Readline).to receive(:readline).and_return('')

          result = described_class.read_resource_display_name(resource: 'custom_dashboard')
          expect(result).to be_nil
        end
      end

      context 'when showing titleized resource as default' do
        it 'displays titleized resource in prompt' do
          allow(Readline).to receive(:readline).and_return('')

          result = described_class.read_resource_display_name(resource: 'custom_dashboard')
          expect(result).to be_nil
        end
      end
    end

    describe '.read_resource_description' do
      context 'when description is given' do
        it 'reads description from stdin' do
          allow(Readline).to receive(:readline).and_return('Test resource description')

          result = described_class.read_resource_description
          expect(result).to eq('Test resource description')
        end
      end

      context 'when empty description is given' do
        it 'returns nil' do
          allow(Readline).to receive(:readline).and_return('')

          result = described_class.read_resource_description
          expect(result).to be_nil
        end
      end
    end

    describe '.feature_categories' do
      it 'returns list of feature categories' do
        categories = described_class.feature_categories
        expect(categories).to be_an(Array)
        expect(categories).not_to be_empty
        expect(categories).to include('custom_dashboards_foundation')
      end
    end
  end
end
