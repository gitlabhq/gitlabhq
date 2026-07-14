# frozen_string_literal: true

module Organizations
  module Release
    # Renders the public Organizations release status doc from the registry.
    #
    # The doc is a view over real system state, never hand-maintained. The output
    # is deterministic (no timestamps) so a spec can assert it stays in sync with
    # the registry.
    class TableRenderer
      DOC_PATH = 'doc/development/organizations/release_status.md'

      def initialize(registry: Registry.instance)
        @registry = registry
      end

      def render
        sections = [
          frontmatter,
          generated_notice,
          intro,
          stages_section,
          flags_section
        ]

        # Each section ends with a newline, so joining with a blank line keeps a
        # single blank line between sections and a single trailing newline.
        sections.join("\n")
      end

      # Writes the rendered doc to disk and returns the path written.
      def write!
        path = Rails.root.join(DOC_PATH)
        File.write(path, render)
        path
      end

      private

      attr_reader :registry

      def frontmatter
        <<~MARKDOWN
          ---
          title: Organizations platform release status
          ---
        MARKDOWN
      end

      def generated_notice
        <<~MARKDOWN
          <!-- This file is generated from config/organizations_release.yml. Do not edit it manually. -->
          <!-- Regenerate it with: bin/rake gitlab:organizations:release:docs -->
        MARKDOWN
      end

      def intro
        <<~MARKDOWN
          Every organization flag and its current stage are listed below.
          The stage determines who can use a flag and whether it can be disabled.
        MARKDOWN
      end

      def stages_section
        rows = Release.stages.map do |stage|
          "| #{stage.label} | #{stage.audience} | #{stage.description} |"
        end

        <<~MARKDOWN
          ## Release stages

          | Stage | Audience | Description |
          |-------|----------|-------------|
          #{rows.join("\n")}
        MARKDOWN
      end

      def flags_section
        return empty_flags_section if sorted_flags.empty?

        rows = sorted_flags.map do |flag|
          "| `#{flag.name}` | #{flag.stage.label} | #{flag.description} |"
        end

        <<~MARKDOWN
          ## Organization flags

          | Flag | Stage | Description |
          |------|-------|-------------|
          #{rows.join("\n")}
        MARKDOWN
      end

      def empty_flags_section
        <<~MARKDOWN
          ## Organization flags

          No organization flags are registered yet. Add a flag to
          `config/organizations_release.yml` when a feature adopts the release layer.
        MARKDOWN
      end

      def sorted_flags
        registry.flags.sort_by { |flag| [Release.stages.index(flag.stage), flag.name] }
      end
    end
  end
end
