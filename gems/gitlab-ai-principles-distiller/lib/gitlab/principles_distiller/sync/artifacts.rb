# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # The contract between the per-principle `distill` CI jobs and the single `collect` job that fans them back in
      # (see `.gitlab/ci/sync-principles/child.gitlab-ci.yml`).
      #
      # Each distill job writes exactly two files into the artifact directory for its principle:
      #
      #   <name>.status  one of updated / unchanged / failed
      #   <name>.md      the fully assembled distilled file, only when
      #                  the status is `updated`
      #
      # The status file is written unconditionally (the CI job declares `artifacts: when: always`), which is what lets
      # the collect job tell the three outcomes apart:
      #
      #   status `updated`    -> distilled content to publish
      #   status `unchanged`  -> ran cleanly, no meaningful diff, nothing to publish
      #   status `failed`     -> failed after retries (phase 1 semantics from #607364)
      #   NO status file      -> the job never ran to completion (concurrency
      #                          starvation, runner outage, job-level timeout)
      #
      # That last case is deliberately NOT folded into `failed`: a principle whose job never ran has not been shown to
      # be undistillable, so reporting it as a distillation failure would be wrong. It gets its own
      # `not_run` state, worded differently in the log, the MR description, and the Slack report.
      class Artifacts
        STATUS_UPDATED   = 'updated'
        STATUS_UNCHANGED = 'unchanged'
        STATUS_FAILED    = 'failed'

        STATUS_SUFFIX  = '.status'
        CONTENT_SUFFIX = '.md'

        # Outcome of a fan-in over one run's artifacts.
        #
        # `contents` maps principle name => assembled file content, matching what `build_distilled_contents` returns in
        # the single-job path, so the publish code downstream is identical either way.
        Collected = Struct.new(:contents, :failed, :not_run, keyword_init: true)

        def initialize(dir)
          @dir = dir
        end

        attr_reader :dir

        # Records one principle's outcome. `content` is required for
        # STATUS_UPDATED and ignored otherwise.
        def write(name, status, content: nil)
          FileUtils.mkdir_p(dir)

          File.write(status_path(name), status)
          File.write(content_path(name), content) if status == STATUS_UPDATED && content
        end

        # Fans the per-principle artifacts back in, in `expected` order so the published MRs keep the manifest's
        # declaration order rather than whatever order the jobs happened to finish in.
        #
        # An unreadable or unrecognised status is treated as `not_run` rather than raising: a corrupt artifact is an
        # infrastructure problem, and misclassifying it as `failed` would wrongly imply the principle is undistillable.
        def collect(expected)
          result = Collected.new(contents: {}, failed: [], not_run: [])

          expected.each do |name|
            case read_status(name)
            when STATUS_UPDATED   then collect_updated(name, result)
            when STATUS_UNCHANGED then puts "  #{name}: #{Rainbow('no meaningful changes').faint}"
            when STATUS_FAILED    then result.failed << name
            else result.not_run << name
            end
          end

          result
        end

        private

        def collect_updated(name, result)
          content = read_content(name)

          # `updated` with no readable body is an incomplete artifact upload, not a distillation failure, so it degrades
          # to `not_run` and gets re-attempted next run rather than being reported as broken.
          if content.nil? || content.empty?
            warn Rainbow("  WARNING: #{name}: status is #{STATUS_UPDATED} but its content artifact is " \
              'missing or empty; treating it as not run').yellow
            result.not_run << name
            return
          end

          result.contents[name] = content
        end

        def read_status(name)
          path = status_path(name)
          return unless File.exist?(path)

          File.read(path).strip
        rescue StandardError => e
          warn Rainbow("  WARNING: could not read the status artifact for #{name} (#{e.message})").yellow
          nil
        end

        def read_content(name)
          path = content_path(name)
          return unless File.exist?(path)

          File.read(path)
        rescue StandardError => e
          warn Rainbow("  WARNING: could not read the content artifact for #{name} (#{e.message})").yellow
          nil
        end

        # Principle names come from the manifest and are already used verbatim as distilled filenames, but they reach
        # here through a CI variable, so they get the same traversal guard as every other workspace path.
        def status_path(name)
          artifact_path("#{name}#{STATUS_SUFFIX}")
        end

        def content_path(name)
          artifact_path("#{name}#{CONTENT_SUFFIX}")
        end

        def artifact_path(filename)
          Workspace.check_path_traversal!(filename)

          File.join(dir, filename)
        end
      end
    end
  end
end
