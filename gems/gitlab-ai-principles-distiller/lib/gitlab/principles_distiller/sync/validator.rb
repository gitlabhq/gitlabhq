# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Fast, network-free check that every SSOT path referenced by the
      # manifest (each principle's `sources[].path` and `baseline:`) resolves
      # to a file on the current branch.
      #
      # Runs at commit/MR time (lefthook + a dedicated CI job) so a doc rename
      # that orphans a manifest reference fails fast, instead of surfacing
      # mid-run on the weekly scheduled sync after expensive Duo workflows have
      # already started. See gitlab-org/gitlab#604077.
      class Validator
        def self.run
          new.run
        end

        def manifest
          @manifest ||= Manifest.new
        end

        # Exits non-zero (via abort) when any referenced SSOT path is missing,
        # listing every broken reference so they can be fixed in one pass.
        def run
          parse_options

          manifest.load

          missing = manifest.missing_source_files
          return success if missing.empty?

          abort(failure_message(missing))
        end

        private

        def parse_options
          OptionParser.new do |opts|
            opts.banner = 'Usage: gitlab-ai-principles-distiller-validate [options]'

            opts.on('--workspace PATH', 'Path to the repository workspace ' \
              '(defaults to $CI_PROJECT_DIR)') do |path|
              Workspace.path = File.expand_path(path)
            end
          end.parse!
        end

        def success
          puts Rainbow("All #{manifest.principles.size} principle(s) reference existing SSOT source files.").green
        end

        def failure_message(missing)
          listed = missing.map { |path| "  - #{path}" }.join("\n")

          Rainbow(<<~MESSAGE).red
            ERROR: #{missing.size} SSOT source file(s) referenced by #{Manifest::MANIFEST_PATH} do not exist:
            #{listed}

            A referenced doc was likely moved or renamed. Update the matching `path:`/`baseline:`
            entries in #{Manifest::MANIFEST_PATH} to point at the current file (a doc converted to a
            directory resolves via its `_index.md`).
          MESSAGE
        end
      end
    end
  end
end
