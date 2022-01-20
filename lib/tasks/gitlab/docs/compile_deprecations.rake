# frozen_string_literal: true

namespace :gitlab do
  namespace :docs do
    desc "Generate deprecation list from individual files"
    task :compile_deprecations do
      require_relative '../../../../tooling/docs/deprecation_handling'
      path = Rails.root.join("doc/update/deprecations.md")
      File.write(path, Docs::DeprecationHandling.new('deprecation').render)
      puts "Deprecations compiled to #{path}"
    end

    desc "Check that the deprecation doc is up to date"
    task :check_deprecations do
      require_relative '../../../../tooling/docs/deprecation_handling'
      path = Rails.root.join("doc/update/deprecations.md")

      contents = Docs::DeprecationHandling.new('deprecation').render
      doc = File.read(path)

      if doc == contents
        puts "Deprecations doc is up to date."
      else
        format_output('Deprecations doc is outdated! You (or your technical writer) can update it by running `bin/rake gitlab:docs:compile_deprecations`.')
        abort
      end
    end

    desc "Generate removal list from individual files"
    task :compile_removals do
      require_relative '../../../../tooling/docs/deprecation_handling'
      path = Rails.root.join("doc/update/removals.md")
      File.write(path, Docs::DeprecationHandling.new('removal').render)
      puts "Removals compiled to #{path}"
    end

    desc "Check that the removal doc is up to date"
    task :check_removals do
      require_relative '../../../../tooling/docs/deprecation_handling'
      path = Rails.root.join("doc/update/removals.md")
      contents = Docs::DeprecationHandling.new('removal').render
      doc = File.read(path)

      if doc == contents
        puts "Removals doc is up to date."
      else
        format_output('Removals doc is outdated! You (or your technical writer) can update it by running `bin/rake gitlab:docs:compile_removals`.')
        abort
      end
    end
  end
end
