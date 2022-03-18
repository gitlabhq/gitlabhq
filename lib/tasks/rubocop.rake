# frozen_string_literal: true
# rubocop:disable Rails/RakeEnvironment

unless Rails.env.production?
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new

  namespace :rubocop do
    namespace :todo do
      desc 'Generate RuboCop todos'
      task :generate do |_task, args|
        require 'rubocop'
        require 'active_support/inflector/inflections'
        require_relative '../../rubocop/todo_dir'
        require_relative '../../rubocop/formatter/todo_formatter'

        # Reveal all pending TODOs so RuboCop can pick them up and report
        # during scan.
        ENV['REVEAL_RUBOCOP_TODO'] = '1'

        # Save cop configuration like `RSpec/ContextWording` into
        # `rspec/context_wording.yml` and not into
        # `r_spec/context_wording.yml`.
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym 'RSpec'
          inflect.acronym 'GraphQL'
        end

        options = %w[
          --parallel
          --format RuboCop::Formatter::TodoFormatter
        ]

        # Convert from Rake::TaskArguments into an Array to make `any?` work as
        # expected.
        cop_names = args.to_a

        todo_dir = RuboCop::TodoDir.new(RuboCop::TodoDir::DEFAULT_TODO_DIR)

        if cop_names.any?
          # We are sorting the cop names to benefit from RuboCop cache which
          # also takes passed parameters into account.
          list = cop_names.sort.join(',')
          options.concat ['--only', list]

          cop_names.each { |cop_name| todo_dir.inspect(cop_name) }
        else
          todo_dir.inspect_all
        end

        puts <<~MSG
          Generating RuboCop TODOs with:
            rubocop #{options.join(' ')}

          This might take a while...
        MSG

        RuboCop::CLI.new.run(options)

        todo_dir.delete_inspected
      end
    end
  end
end

# rubocop:enable Rails/RakeEnvironment
