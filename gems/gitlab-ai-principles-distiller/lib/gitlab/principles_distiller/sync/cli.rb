# frozen_string_literal: true

require 'optparse'

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Parses and dispatches the sync command's explicit subcommands.
      class CLI
        COMMANDS = {
          'distill' => {
            description: 'Scan, distill, and optionally publish affected principles.',
            dispatch: ->(sync, options, _arguments) { sync.distill_and_publish(options) }
          },
          'generate-pipeline' => {
            description: 'Write the child pipeline for affected principles.',
            dispatch: ->(sync, options, _arguments) { sync.generate_child_pipeline(options) }
          },
          'distill-one' => {
            description: 'Distill one principle and write its artifact.',
            argument: 'NAME',
            dispatch: ->(sync, _options, arguments) { sync.distill_one(arguments.first) }
          },
          'collect' => {
            description: 'Collect principle artifacts and optionally publish them.',
            argument: 'NAMES',
            # The generated child pipeline passes an empty list when no principles need distillation.
            allow_empty_argument: true,
            dispatch: ->(sync, options, arguments) { sync.collect(parse_names(arguments.first), push: options[:push]) }
          },
          'check-fences' => {
            description: 'Check Duo review instruction fences for drift.',
            dispatch: ->(sync, options, _arguments) do
              sync.check_duo_instructions_fences(warn_stale: options[:warn_stale])
            end
          },
          'reconcile-fences' => {
            description: 'Regenerate Duo review instruction fences.',
            dispatch: ->(sync, options, _arguments) do
              sync.reconcile_duo_instructions_fences(push: options[:push])
            end
          }
        }.freeze

        def self.run(argv = ARGV)
          new.run(argv)
        end

        def self.parse_names(names)
          names.split(',').map(&:strip).reject(&:empty?)
        end

        def run(argv)
          arguments = argv.dup
          parse_global_options(arguments)
          command_name = arguments.shift

          abort_with_help('ERROR: missing subcommand') if command_name.nil?

          command = COMMANDS[command_name]
          abort_with_help("ERROR: unknown subcommand '#{command_name}'") if command.nil?

          options = parse_command_options(command_name, command, arguments)
          validate_arguments!(command_name, command, arguments)
          command[:dispatch].call(Sync.new, options, arguments)
        end

        private

        def parse_global_options(arguments)
          OptionParser.new do |opts|
            opts.banner = usage
            workspace_option(opts)
            opts.on('-h', '--help', 'Show this help') do
              puts opts
              # rubocop:disable Rails/Exit -- standalone CLI exits after printing requested help
              exit
              # rubocop:enable Rails/Exit
            end
          end.order!(arguments)
        rescue OptionParser::ParseError => e
          abort_with_help("ERROR: #{e.message}")
        end

        def parse_command_options(command_name, command, arguments)
          options = {}
          parser = OptionParser.new do |opts|
            opts.banner = command_usage(command_name, command)
            configure_command_options(command_name, opts, options)
            opts.on('-h', '--help', 'Show this help') do
              puts opts
              # rubocop:disable Rails/Exit -- standalone CLI exits after printing requested help
              exit
              # rubocop:enable Rails/Exit
            end
          end
          parser.parse!(arguments)
          options
        rescue OptionParser::InvalidOption => e
          abort "ERROR: unknown option '#{e.args.first}' for '#{command_name}'\n\n#{parser}"
        rescue OptionParser::ParseError => e
          abort "ERROR: #{e.message}\n\n#{parser}"
        end

        def validate_arguments!(command_name, command, arguments)
          return if command[:argument].nil? && arguments.empty?

          return if command[:argument] && arguments.size == 1 && valid_argument?(command, arguments.first)

          abort "ERROR: #{command_usage(command_name, command)}"
        end

        def valid_argument?(command, argument)
          command[:allow_empty_argument] || !argument.empty?
        end

        def configure_command_options(command_name, opts, options)
          case command_name
          when 'distill'
            distill_options(opts, options)
          when 'generate-pipeline'
            generate_pipeline_options(opts, options)
          when 'distill-one'
            workspace_options(opts, options)
          when 'collect'
            collect_options(opts, options)
          when 'check-fences'
            check_fences_options(opts, options)
          when 'reconcile-fences'
            reconcile_fences_options(opts, options)
          end
        end

        def distill_options(opts, options)
          workspace_option(opts)
          opts.on('--dry-run', 'Show what would be done without making changes') { options[:dry_run] = true }
          opts.on('--push', 'Create a branch, commit, push, and open an MR') { options[:push] = true }
          opts.on('--force', 'Force re-distillation, ignoring checksums') { options[:force] = true }
          opts.on('--only NAMES', 'Comma-separated principle names to process') do |names|
            options[:only] = parse_names(names)
          end
          opts.on('--rewrite', 'Rewrite all items from scratch') { options[:rewrite] = true }
        end

        def generate_pipeline_options(opts, options)
          workspace_option(opts)
          opts.on('--force', 'Force re-distillation, ignoring checksums') { options[:force] = true }
          opts.on('--only NAMES', 'Comma-separated principle names to process') do |names|
            options[:only] = parse_names(names)
          end
        end

        def collect_options(opts, options)
          workspace_option(opts)
          opts.on('--push', 'Create a branch, commit, push, and open an MR') { options[:push] = true }
        end

        def check_fences_options(opts, options)
          workspace_option(opts)
          opts.on('--warn-stale', 'Treat stale fences as a non-blocking warning') { options[:warn_stale] = true }
        end

        def reconcile_fences_options(opts, options)
          workspace_option(opts)
          opts.on('--push', 'Open or update a reconcile MR') { options[:push] = true }
        end

        def workspace_options(opts, _options)
          workspace_option(opts)
        end

        def workspace_option(opts)
          opts.on('--workspace PATH', 'Path to the repository workspace') do |path|
            Workspace.path = path
          end
        end

        def parse_names(names)
          self.class.parse_names(names)
        end

        def usage
          <<~USAGE
            Usage: gitlab-ai-principles-distiller-sync [--workspace PATH] <subcommand> [options]

            Subcommands:
            #{COMMANDS.map { |name, command| format('  %-18s %s', name, command[:description]) }.join("\n")}
          USAGE
        end

        def command_usage(command_name, command)
          argument = command[:argument] ? " #{command[:argument]}" : ''
          "Usage: gitlab-ai-principles-distiller-sync #{command_name} [options]#{argument}"
        end

        def abort_with_help(message)
          abort "#{message}\n\n#{usage}"
        end
      end
    end
  end
end
