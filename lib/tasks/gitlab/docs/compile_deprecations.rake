# frozen_string_literal: true

namespace :gitlab do
  namespace :docs do
    COLOR_CODE_RESET = "\e[0m"
    COLOR_CODE_RED = "\e[31m"
    COLOR_CODE_GREEN = "\e[32m"

    desc "Generate deprecation list from individual files"
    task :compile_deprecations do
      require_relative '../../../../tooling/docs/deprecation_handling'
      path = Rails.root.join("doc/update/deprecations.md")
      File.write(path, Docs::DeprecationHandling.new('deprecation').render)
      puts "#{COLOR_CODE_GREEN}INFO: Deprecations compiled to #{path}.#{COLOR_CODE_RESET}"
    end

    desc "Check that the deprecation documentation is up to date"
    task :check_deprecations do
      require_relative '../../../../tooling/docs/deprecation_handling'
      path = Rails.root.join("doc/update/deprecations.md")

      contents = Docs::DeprecationHandling.new('deprecation').render
      doc = File.read(path)

      if doc == contents
        puts "#{COLOR_CODE_GREEN}INFO: Deprecations documentation is up to date.#{COLOR_CODE_RESET}"
      else
        warn <<~EOS
        #{COLOR_CODE_RED}ERROR: Deprecations documentation is outdated!#{COLOR_CODE_RESET}
        To update the deprecations documentation, either:

        - Run `bin/rake gitlab:docs:compile_deprecations` and commit the changes to this branch.
        - Have a technical writer resolve the issue.
        EOS
        abort
      end
    end
  end
end
