# frozen_string_literal: true

namespace :gitlab do
  namespace :docs do
    desc "Generate deprecation list from individual files"
    task :compile_deprecations do
      require_relative '../../../../tooling/deprecations/docs/renderer'

      source_files = Rake::FileList.new("data/deprecations/**/*.yml") do |fl|
        fl.exclude(/example\.yml/)
      end

      deprecations = source_files.map do |file|
        YAML.load_file(file)
      end

      deprecations.sort_by! { |d| -d["removal_milestone"].to_f }

      milestones = deprecations.map { |d| d["removal_milestone"].to_f }.uniq

      contents = Deprecations::Docs::Renderer
        .render(deprecations: deprecations, milestones: milestones)

      File.write(
        File.expand_path("doc/deprecations/index.md", "#{__dir__}/../../../.."),
        contents)

      puts "Deprecations compiled to doc/deprecations/index.md"
    end
  end
end
