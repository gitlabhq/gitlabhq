# frozen_string_literal: true

module SystemCheck
  # Helpers used inside a SystemCheck instance to standardize output responses
  module Helpers
    include ::Gitlab::TaskHelpers

    # Display a message telling to fix and rerun the checks
    def fix_and_rerun
      $stdout.puts Rainbow('  Please fix the error above and rerun the checks.').red
    end

    # Display a formatted list of references (documentation or links) where to find more information
    #
    # @param [Array<String>] sources one or more references (documentation or links)
    def for_more_information(*sources)
      $stdout.puts Rainbow('  For more information see:').blue
      sources.each do |source|
        $stdout.puts "  #{source}"
      end
    end

    # Construct a help page based on the instance's external_url
    #
    # @param <String> path of the documentation page
    # @param <String> anchor to the specific docs heading
    #
    # @return <String> URL of the help page
    def construct_help_page_url(path, anchor = nil)
      Rails.application.routes.url_helpers.help_page_url(path, anchor)
    end

    def see_installation_guide_section(section)
      "doc/install/installation.md in section \"#{section}\""
    end

    # @deprecated This will no longer be used when all checks were executed using SystemCheck
    def finished_checking(component)
      $stdout.puts ''
      $stdout.puts "Checking #{Rainbow(component).yellow} ... #{Rainbow('Finished').green}"
      $stdout.puts ''
    end

    # @deprecated This will no longer be used when all checks were executed using SystemCheck
    def start_checking(component)
      $stdout.puts "Checking #{Rainbow(component).yellow} ..."
      $stdout.puts ''
    end

    # Display a formatted list of instructions on how to fix the issue identified by the #check?
    #
    # @param [Array<String>] steps one or short sentences with help how to fix the issue
    def try_fixing_it(*steps)
      steps = steps.shift if steps.first.is_a?(Array)

      $stdout.puts Rainbow('  Try fixing it:').blue
      steps.each do |step|
        $stdout.puts "  #{step}"
      end
    end

    def sanitized_message(project)
      if should_sanitize?
        "#{Rainbow(project.namespace_id.to_s).yellow}/#{Rainbow(project.id.to_s).yellow} ... "
      else
        "#{Rainbow(project.full_name).yellow} ... "
      end
    end

    def should_sanitize?
      ENV['SANITIZE'] == 'true'
    end

    def omnibus_gitlab?
      Dir.pwd == '/opt/gitlab/embedded/service/gitlab-rails'
    end

    def sudo_gitlab(command)
      "sudo -u #{gitlab_user} -H #{command}"
    end
  end
end
