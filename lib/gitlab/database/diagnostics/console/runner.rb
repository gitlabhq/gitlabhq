# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        class Runner
          HEADER = 'Database diagnostics'
          SUMMARY = 'Summary'
          CLEAN = 'No issues found.'
          QUIT = 'Quit'
          PAGER = %w[less -R].freeze

          # interactive: nil auto-detects a terminal, so specs and pipes get the full report.
          def initialize(
            database_names:, output: $stdout, views: Console::VIEWS, interactive: nil, prompt: nil, pager: nil)
            @database_names = database_names
            @printer = Printer.new(output: output)
            @views = views
            @interactive = interactive.nil? ? output.tty? && $stdin.tty? : interactive
            @prompt = prompt
            @pager = pager
          end

          # Views render into per-view buffers so the summary can precede their
          # sections and interactive sessions can print one check on demand.
          def run
            sections = with_primary_reads do
              views.map { |view_class| render_view(view_class) }
            end

            print_header
            print_summary(sections)

            if interactive?
              browse(sections)
            else
              sections.each { |section| print_body(section[:body]) }
            end

            Findings.worst(total_counts(sections).keys)
          end

          private

          attr_reader :database_names, :printer, :views

          def interactive?
            @interactive
          end

          # DatabaseInformation forces the primary only for its vacuum query, so the
          # report could otherwise describe a replica. The admin page does not do this.
          def with_primary_reads(&block)
            ::Gitlab::Database::LoadBalancing::SessionMap
              .with_sessions(::Gitlab::Database::LoadBalancing.base_models)
              .use_primary(&block)
          end

          def render_view(view_class)
            body = StringIO.new

            { title: view_class.title, counts: run_view(view_class, Printer.new(output: body)), body: body.string }
          end

          def run_view(view_class, body_printer)
            view_class.new(databases: databases, printer: body_printer).run
          rescue StandardError => e
            body_printer.status(view_class.title, FAILED, Findings::ERROR)
            body_printer.detail("#{e.class}: #{e.message}")
            body_printer.blank_line

            { Findings::ERROR => 1 }
          end

          def browse(sections)
            loop do
              choice = prompt.select('View details?', cycle: true, quiet: true) do |menu|
                sections.each { |section| menu.choice(section[:title], section) }
                menu.choice(QUIT, :quit)
              end

              break if choice == :quit

              page(choice[:body])
            end
          end

          def page(body)
            pager.call(body)
          rescue Errno::ENOENT
            print_body(body)
          end

          # less mimics man: scroll with arrows or j/k, press q to return to the menu.
          def pager
            @pager ||= ->(body) { IO.popen(PAGER, 'w') { |io| io.write(body) } }
          end

          def prompt
            @prompt ||= begin
              # The gem is require: false in the Gemfile; only this TTY path needs it.
              require 'tty-prompt'

              TTY::Prompt.new(interrupt: :exit)
            end
          end

          def databases
            @databases ||= DatabaseInformation.execute(database_names: database_names)[:databases]
          end

          def print_header
            printer.line(HEADER)
            printer.line("Databases: #{database_names.join(', ')}")
          end

          def print_summary(sections)
            printer.section(SUMMARY)

            sections.each do |section|
              status = Console.summarize(section[:counts]) || OK
              printer.status(section[:title], status, Findings.worst(section[:counts].keys))
            end

            printer.blank_line

            summary = Console.summarize(total_counts(sections))
            printer.line(summary ? "Completed with #{summary}." : CLEAN)
          end

          def print_body(body)
            body.each_line { |line| printer.line(line.chomp) }
          end

          def total_counts(sections)
            Console.merge_counts(sections.pluck(:counts))
          end
        end
      end
    end
  end
end
