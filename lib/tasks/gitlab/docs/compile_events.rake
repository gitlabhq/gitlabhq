# frozen_string_literal: true

namespace :gitlab do
  namespace :docs do
    desc "Generate event store index from YAML files in data/events/"
    task :compile_events do
      require_relative '../../../../tooling/docs/event_handling'
      path = Rails.root.join('doc/development/eventstore/events.md')
      File.write(path, Docs::EventHandling.new.render)
      puts "#{COLOR_CODE_GREEN}INFO: Event index compiled to #{path}.#{COLOR_CODE_RESET}"
    end

    desc "Check that the event store index is up to date"
    task :check_events do
      require_relative '../../../../tooling/docs/event_handling'
      path = Rails.root.join('doc/development/eventstore/events.md')

      contents = Docs::EventHandling.new.render

      if File.exist?(path) && File.read(path) == contents
        puts "#{COLOR_CODE_GREEN}INFO: Event store index is up to date.#{COLOR_CODE_RESET}"
      else
        warn <<~MSG
          #{COLOR_CODE_RED}ERROR: Event store index is outdated!#{COLOR_CODE_RESET}
          Run `bin/rake gitlab:docs:compile_events` and commit the result.
        MSG
        abort
      end
    end
  end
end
