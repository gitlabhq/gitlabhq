# frozen_string_literal: true

unless Rails.env.production?
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new

  namespace :rubocop do
    namespace :check do
      desc 'Run RuboCop check gracefully'
      task :graceful do |_task, args|
        require_relative '../../rubocop/check_graceful_task'

        # Don't reveal TODOs in this run.
        ENV.delete('REVEAL_RUBOCOP_TODO')

        result = RuboCop::CheckGracefulTask.new($stdout).run(args.extras)
        exit result if result.nonzero?
      end
    end

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

        todo_dir = RuboCop::TodoDir.new(RuboCop::Formatter::TodoFormatter.base_directory)

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

    desc 'Update documentation of all cops'
    task :docs do
      require 'yard'
      require 'rubocop'

      YARD::Rake::YardocTask.new(:yard_rubocop_docs) do |task|
        task.files = ['rubocop/cop/**/*.rb'] + gitlab_styles_cops
        task.options = ['--no-output']
      end

      Rake::Task[:yard_rubocop_docs].invoke

      cops_registry = RuboCop::Cop::Registry.new
      gitlab_cops.each { |cop| cops_registry.enlist(cop) }

      FileUtils.rm_rf('tmp/docs/')
      FileUtils.rm_rf('rubocop/docs-hugo/content/doc/')

      require_relative '../../rubocop/cops_documentation_generator'

      departments = cops_registry.map { |cop_class| cop_class.to_s.split("::")[-2] }.uniq
      formatter = RuboCop::CopsDocumentationGenerator::Formatters::HugoMarkdown.new
      base_dir = 'tmp'

      RuboCop::CopsDocumentationGenerator.new(departments:, cops_registry:, formatter:, base_dir:).call

      puts "Moving content to `rubocop/docs-hugo/content/doc/`..."
      FileUtils.mv('tmp/docs/modules/ROOT/pages/', 'rubocop/docs-hugo/content/doc/')
      FileUtils.rm_rf('tmp/docs/')

      update_headers_for_cop_documentations
    end

    def update_headers_for_cop_documentations
      documentation_metadata = <<~META
        ---
        title: %{title}
        ---
      META

      Dir.glob('rubocop/docs-hugo/content/doc/*.md').each do |file|
        content = File.read(file)
        page_h1_match = content.match(/^# +(.*)\n/)
        title = page_h1_match.present? ? "#{page_h1_match[1]} RuboCop docs" : 'RuboCop docs'
        content.sub!(page_h1_match[0], '') if page_h1_match
        current_documentation_metadata = format(documentation_metadata, title:)
        File.write(file, current_documentation_metadata + content) unless content.start_with?("---\n")
      end
    end

    def gitlab_cops
      # Pre-load existing cops so we can exclude them from the list of cops we generate documentation for
      require 'rubocop'
      require 'rubocop-capybara'
      require 'rubocop-factory_bot'
      require 'rubocop-graphql'
      require 'rubocop-performance'
      require 'rubocop-rails'
      require 'rubocop-rspec'
      require 'rubocop-rspec_rails'

      existing_cops = RuboCop::Cop::Registry.global.to_a

      Dir['rubocop/cop/**/*.rb'].each { |file| require_relative File.join('../..', file) }
      gitlab_styles_cops.each { |file| require file }

      RuboCop::Cop::Registry.global.to_a - existing_cops
    end

    def gitlab_styles_cops
      return @gitlab_styles_cops if defined?(@gitlab_styles_cops)

      gem_dir = Gem::Specification.find_by_name('gitlab-styles').gem_dir
      @gitlab_styles_cops ||= Dir["#{gem_dir}/lib/rubocop/cop/**/*.rb"]
    end
  end
end
