# frozen_string_literal: true

module SystemCheck
  # Helpers used inside a SystemCheck instance to standardize output responses
  module Helpers
    include ::Gitlab::TaskHelpers

    DOC_PATH_PATTERN = %r{\Adoc/\S+\z}

    # Write a line to stdout. Wraps +puts+ so that callers do not trigger
    # the +Rails/Output+ cop.
    def say(message = '')
      puts message # rubocop:disable Rails/Output -- system check CLI output
    end

    # Display a message telling to fix and rerun the checks
    def fix_and_rerun
      say Rainbow('  Please fix the error above and rerun the checks.').red
    end

    # Display a formatted list of references (documentation or links) where to find more information
    #
    # @param [Array<String>] sources one or more references (documentation or links).
    #   Sources starting with "doc/" are automatically converted to full help page URLs.
    #   Full URLs (http/https) are displayed as-is.
    def for_more_information(*sources)
      say Rainbow('  For more information see:').blue
      sources.each do |source|
        say "  #{resolve_doc_url(source)}"
      end
    end

    def see_installation_guide_section(section)
      "doc/install/self_compiled/_index.md##{section.parameterize}"
    end

    # @deprecated This will no longer be used when all checks were executed using SystemCheck
    def finished_checking(component)
      say ''
      say "Checking #{Rainbow(component).yellow} ... #{Rainbow('Finished').green}"
      say ''
    end

    # @deprecated This will no longer be used when all checks were executed using SystemCheck
    def start_checking(component)
      say "Checking #{Rainbow(component).yellow} ..."
      say ''
    end

    # Display a formatted list of instructions on how to fix the issue identified by the #check?
    #
    # @param [Array<String>] steps one or short sentences with help how to fix the issue
    def try_fixing_it(*steps)
      steps = steps.shift if steps.first.is_a?(Array)

      say Rainbow('  Try fixing it:').blue
      steps.each do |step|
        say "  #{step}"
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

    private

    # Converts a relative doc path to a full help page URL.
    # Passes through sources that are already full URLs.
    #
    # @param source [String] a doc path (e.g. "doc/administration/geo/index.md")
    #   or a full URL (e.g. "https://about.gitlab.com/solutions/geo/")
    # @return [String] a full URL
    def resolve_doc_url(source)
      return source unless source.match?(DOC_PATH_PATTERN)

      path = source.delete_prefix('doc/')
      file_path, anchor = path.split('#', 2)

      options = {}
      options[:anchor] = anchor if anchor

      # rubocop:disable Gitlab/DocumentationLinks/Link -- path is dynamically resolved from caller input
      Rails.application.routes.url_helpers.help_page_url(file_path, **options)
      # rubocop:enable Gitlab/DocumentationLinks/Link
    end
  end
end
