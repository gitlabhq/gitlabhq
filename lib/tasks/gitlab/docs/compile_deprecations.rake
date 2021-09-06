# frozen_string_literal: true

namespace :gitlab do
  namespace :docs do
    desc "Generate deprecation list from individual files"
    task :compile_deprecations do
      require_relative '../../../../tooling/deprecations/docs'

      File.write(Deprecations::Docs.path, Deprecations::Docs.render)

      puts "Deprecations compiled to #{Deprecations::Docs.path}"
    end

    desc "Check that the deprecation doc is up to date"
    task :check_deprecations do
      require_relative '../../../../tooling/deprecations/docs'

      contents = Deprecations::Docs.render
      doc = File.read(Deprecations::Docs.path)

      if doc == contents
        puts "Deprecations doc is up to date."
      else
        format_output('Deprecations doc is outdated! Please update it by running `bundle exec rake gitlab:docs:compile_deprecations`.')
        abort
      end
    end
  end
end
