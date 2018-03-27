module SystemCheck
  module Helpers
    include ::Gitlab::TaskHelpers

    # Display a message telling to fix and rerun the checks
    def fix_and_rerun
      $stdout.puts '  Please fix the error above and rerun the checks.'.color(:red)
    end

    # Display a formatted list of references (documentation or links) where to find more information
    #
    # @param [Array<String>] sources one or more references (documentation or links)
    def for_more_information(*sources)
      $stdout.puts '  For more information see:'.color(:blue)
      sources.each do |source|
        $stdout.puts "  #{source}"
      end
    end

    def see_installation_guide_section(section)
      "doc/install/installation.md in section \"#{section}\""
    end

    # @deprecated This will no longer be used when all checks were executed using SystemCheck
    def finished_checking(component)
      $stdout.puts ''
      $stdout.puts "Checking #{component.color(:yellow)} ... #{'Finished'.color(:green)}"
      $stdout.puts ''
    end

    # @deprecated This will no longer be used when all checks were executed using SystemCheck
    def start_checking(component)
      $stdout.puts "Checking #{component.color(:yellow)} ..."
      $stdout.puts ''
    end

    # Display a formatted list of instructions on how to fix the issue identified by the #check?
    #
    # @param [Array<String>] steps one or short sentences with help how to fix the issue
    def try_fixing_it(*steps)
      steps = steps.shift if steps.first.is_a?(Array)

      $stdout.puts '  Try fixing it:'.color(:blue)
      steps.each do |step|
        $stdout.puts "  #{step}"
      end
    end

    def sanitized_message(project)
      if should_sanitize?
        "#{project.namespace_id.to_s.color(:yellow)}/#{project.id.to_s.color(:yellow)} ... "
      else
        "#{project.full_name.color(:yellow)} ... "
      end
    end

    def should_sanitize?
      if ENV['SANITIZE'] == 'true'
        true
      else
        false
      end
    end

    def omnibus_gitlab?
      Dir.pwd == '/opt/gitlab/embedded/service/gitlab-rails'
    end

    def sudo_gitlab(command)
      "sudo -u #{gitlab_user} -H #{command}"
    end
  end
end
