# frozen_string_literal: true

module Mcp
  module Tools
    module Jobs
      class GetArtifactFileService < Base::CustomService
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize
        include ::Mcp::Tools::Concerns::UrlParser

        MAX_BYTE_LIMIT = 1.megabyte
        MIN_BYTE_OFFSET = 0
        # Hard ceiling on bytes inflated per call: the zip stream cannot seek, so reaching
        # an offset inflates everything before it, and the entry's declared size cannot be
        # trusted to bound that (a deflate bomb can declare anything).
        MAX_BYTE_OFFSET = 100.megabytes
        # Zip::File.open builds one Ruby object per entry, so a small archive stuffed
        # with a huge number of tiny files is a memory bomb independent of its byte size.
        MAX_ARCHIVE_ENTRIES = 1_000
        # The whole archive is downloaded to read one entry, and this runs in a
        # synchronous request, unlike the workers that read artifact archives.
        MAX_ARCHIVE_BYTES = 20.megabytes
        # libgit2's binary sniff window: binary detection looks at the first 8000 bytes.
        SAMPLE_BYTES = 8000
        LISTED_PATHS_LIMIT = 20
        NOT_FOUND = 'Job not found or inaccessible'
        JOB_URL_PATTERN = %r{\A/(?<project>.+)/-/jobs/(?<job_id>\d+)(?:/artifacts/(?:file|raw)/(?<path>.+))?\z}

        register_version '0.1.0', {
          toolset: :ci,
          description: 'Read a file from inside the artifacts archive of a CI/CD job as text. ' \
            'To discover what a job or pipeline produced, use get_job or get_pipeline with ' \
            'include: artifacts. For large files, page through with byte_offset and byte_limit.',
          annotations: {
            readOnlyHint: true
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the job, for example ' \
                  'https://gitlab.com/gitlab-org/gitlab/-/jobs/123. ' \
                  'Provide this, or project_id and job_id.'
              },
              project_id: {
                type: 'string',
                description: 'ID or full path of the project. Required if url is not provided.'
              },
              job_id: {
                type: 'integer',
                description: 'ID of the job. Required if url is not provided.'
              },
              artifact_path: {
                type: 'string',
                description: 'Path of the file inside the artifacts archive, for example coverage/index.html.'
              },
              byte_offset: {
                type: 'integer',
                minimum: MIN_BYTE_OFFSET,
                maximum: MAX_BYTE_OFFSET,
                description: 'Byte offset to start reading the file from.'
              },
              byte_limit: {
                type: 'integer',
                minimum: 1,
                maximum: MAX_BYTE_LIMIT,
                description: 'Maximum number of bytes to return.'
              }
            },
            required: %w[artifact_path]
          }
        }

        # A job we cannot find and a job we cannot read get the same response, so the caller
        # cannot probe for jobs they have no access to.
        override :authorization_error_message
        def authorization_error_message
          NOT_FOUND
        end

        protected

        # Unlike read_build, this folds in the project's artifact-access settings,
        # matching the REST artifact download endpoints.
        def auth_ability
          :read_job_artifacts
        end

        def auth_target(params)
          @arguments = params[:arguments] || {}

          job || raise(ArgumentError, NOT_FOUND)
        end

        def perform_default(arguments = {})
          @arguments = arguments || {}

          return excluded_response if file_excluded?(job.project, artifact_path)
          # available_artifacts?, not artifacts?: artifacts past expire_at but kept by
          # "Keep artifacts from most recent successful jobs" stay downloadable.
          return no_archive_error unless job.available_artifacts?
          return archive_too_large_error if job.artifacts_size > MAX_ARCHIVE_BYTES
          return too_many_entries_error if archive_entry_count_exceeded?
          return entry_not_found_error if metadata_says_missing?

          read_from_archive
        end

        private

        attr_reader :arguments

        def job
          project = find_project!(target[:project])

          # Same lookup as `find_build!` in lib/api/helpers.rb, which backs the REST artifact routes.
          # rubocop:disable Database/AvoidUnpartitionedCiRelations -- no partition key available
          project.builds.find_by_id(target[:job_id])
          # rubocop:enable Database/AvoidUnpartitionedCiRelations
        end
        strong_memoize_attr :job

        def target
          if arguments[:url].present?
            if arguments[:project_id].present? || arguments[:job_id].present?
              raise ArgumentError, 'Provide either url, or project_id and job_id, not both'
            end

            parse_job_url(arguments[:url])
          else
            if arguments[:project_id].blank? || arguments[:job_id].blank?
              raise ArgumentError, 'Provide either url, or project_id and job_id'
            end

            { project: arguments[:project_id].to_s, job_id: arguments[:job_id] }
          end
        end
        strong_memoize_attr :target

        def parse_job_url(url)
          path = "/#{extract_path_from_url(url)}"

          match = path.match(JOB_URL_PATTERN)

          unless match
            raise ArgumentError, "Invalid job URL: '#{url}'. Expected a URL like " \
              'https://gitlab.com/<project path>/-/jobs/<job id>'
          end

          # Rails percent-encodes artifact file URLs, so decode before comparing.
          url_artifact_path = match[:path] && unescape_and_scrub_uri(match[:path])

          if url_artifact_path.present? && normalized_input_path.present? && url_artifact_path != normalized_input_path
            raise ArgumentError, "Artifact path mismatch: artifact_path is '#{normalized_input_path}' " \
              "but url contains '#{url_artifact_path}'"
          end

          { project: match[:project], job_id: match[:job_id].to_i }
        end

        def artifact_path
          path = normalized_input_path

          raise ArgumentError, 'artifact_path must not be empty' if path.blank?
          raise ArgumentError, "artifact_path must be a file path, not a directory: '#{path}'" if path.end_with?('/')

          unless ::Gitlab::Ci::Build::Artifacts::Path.new(path).valid?
            raise ArgumentError, "artifact_path is not a valid path: '#{path}'"
          end

          if ::Gitlab::PathTraversal.path_traversal?(path)
            raise ArgumentError, "artifact_path must not contain a path traversal sequence: '#{path}'"
          end

          path
        end
        strong_memoize_attr :artifact_path

        def normalized_input_path
          arguments[:artifact_path].to_s.strip.delete_prefix('/')
        end

        # The archive's metadata file lists every entry, so a missing path is answered
        # without downloading the archive itself.
        def metadata_says_missing?
          !!metadata_entry && !metadata_entry.exists?
        end

        # Not artifacts_metadata?: that folds in artifacts?, which is false for
        # expired-but-locked artifacts, and availability is already checked above.
        def metadata_entry
          return unless job.artifacts_metadata&.exists?

          job.artifacts_metadata_entry(artifact_path)
        end
        strong_memoize_attr :metadata_entry

        # The metadata file is written by GitLab at upload, so its size for the entry
        # is trusted over the archive's self-declared one.
        def metadata_entry_size
          metadata_entry.total_size if metadata_entry&.exists?
        end

        def archive_entry_count_exceeded?
          all_entries.present? && all_entries.length > MAX_ARCHIVE_ENTRIES
        end

        def all_entries
          return unless job.artifacts_metadata&.exists?

          job.artifacts_metadata_entry('', recursive: true).entries
        end
        strong_memoize_attr :all_entries

        def read_from_archive
          job.artifacts_file.use_open_file(unlink_early: false) do |open_file|
            # rubocop:disable Performance/Rubyzip -- reading one entry needs random access by name
            Zip::File.open(open_file.file_path) do |zip_file|
              entry = zip_file.find_entry(artifact_path)

              if entry.nil?
                entry_not_found_error
              elsif entry.ftype != :file
                not_regular_file_error
              else
                read_entry(entry)
              end
            end
            # rubocop:enable Performance/Rubyzip
          end
        end

        def read_entry(entry)
          byte_offset = arguments[:byte_offset] || MIN_BYTE_OFFSET
          byte_limit = arguments[:byte_limit] || MAX_BYTE_LIMIT
          total_bytes = metadata_entry_size || entry.size

          # Returning before get_input_stream means nothing is inflated.
          return success_response(+'', byte_offset, total_bytes, truncated: false) if byte_offset >= total_bytes

          # A stored entry that over-declares its size would otherwise read neighboring
          # archive bytes into the window.
          byte_limit = [byte_limit, total_bytes - byte_offset].min

          entry.get_input_stream do |stream|
            sample = stream.read([SAMPLE_BYTES, total_bytes].min).to_s

            if ::Gitlab::EncodingHelper.detect_libgit2_binary?(sample)
              binary_error(sample, total_bytes)
            else
              content, more_data = window_from(stream, sample, byte_offset, byte_limit)
              truncated = more_data && byte_offset + content.bytesize < total_bytes

              success_response(content, byte_offset, total_bytes, truncated: truncated)
            end
          end
        end

        # The zip stream cannot seek, so the window is the already-read binary sample plus
        # sequential reads. "More data" is probed from the stream, not the declared size: a
        # corrupt entry that under-delivers must not report truncated or the agent loops.
        def window_from(stream, sample, byte_offset, byte_limit)
          content = if byte_offset < sample.bytesize
                      head = sample.byteslice(byte_offset, byte_limit)
                      remaining = byte_limit - head.bytesize

                      remaining > 0 ? head + stream.read(remaining).to_s : head
                    else
                      discard(stream, byte_offset - sample.bytesize)
                      stream.read(byte_limit).to_s
                    end

          more_in_sample = byte_offset + content.bytesize < sample.bytesize
          [content, more_in_sample || !stream.read(1).to_s.empty?]
        end

        # Skipped bytes are read in small chunks instead of one read, so a large
        # byte_offset does not allocate the skipped part of the file in memory.
        def discard(stream, count)
          while count > 0
            chunk = stream.read([count, 128.kilobytes].min)
            break if chunk.nil? || chunk.empty?

            count -= chunk.bytesize
          end
        end

        def success_response(content, byte_offset, total_bytes, truncated:)
          returned_start = [byte_offset, total_bytes].min
          returned_end = returned_start + content.bytesize

          system_instruction = if truncated
                                 "Artifact file truncated. Remaining: #{total_bytes - returned_end} bytes. " \
                                   "Call again with {\"byte_offset\": #{returned_end}}."
                               end

          data = {
            path: artifact_path,
            job_id: job.id,
            metadata: {
              total_bytes: total_bytes,
              returned: { start: returned_start, end: returned_end },
              truncated: truncated
            },
            # Zip reads come back binary-encoded, and a byte window can split a multi-byte
            # character, so re-encode before the response is serialized to JSON.
            content: (+content).force_encoding(Encoding::UTF_8).scrub,
            system_instruction: system_instruction
          }.compact

          formatted_content = [{ type: 'text', text: Gitlab::Json.generate(data) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, data)
        end

        def no_archive_error
          message = "Job #{job.id} has no artifacts archive."
          message += ' The artifacts have expired.' if job.artifacts_expired?

          error(message)
        end

        def too_many_entries_error
          error("The artifacts archive of job #{job.id} has more than #{MAX_ARCHIVE_ENTRIES} entries, " \
            "which exceeds what this tool reads. Download it from #{download_url} instead.")
        end

        def archive_too_large_error
          error("The artifacts archive of job #{job.id} is #{job.artifacts_size} bytes, which exceeds " \
            "the #{MAX_ARCHIVE_BYTES} bytes this tool reads. Download it from #{download_url} instead.")
        end

        def entry_not_found_error
          message = "Artifact file '#{artifact_path}' not found in the artifacts archive of job #{job.id}."
          paths = listable_paths
          message += " Files in the archive include: #{paths.join(', ')}." if paths.any?

          error(message)
        end

        def not_regular_file_error
          error("Artifact path '#{artifact_path}' in job #{job.id} is not a regular file and cannot be read.")
        end

        # CE has no context exclusions. Overridden in EE.
        def file_excluded?(_project, _path)
          false
        end

        def excluded_response
          error("File '#{artifact_path}' is excluded from AI context by this project's settings and cannot be read.")
        end

        def binary_error(sample, total_bytes)
          file_type = ::Gitlab::Utils::MimeType.from_string(sample) || 'binary'

          error("Artifact file '#{artifact_path}' in job #{job.id} is binary (#{file_type}) and cannot be " \
            "returned as text. Size: #{total_bytes} bytes. It can be viewed at " \
            "#{::Gitlab::Routing.url_helpers.raw_project_job_artifacts_url(job.project, job, path: artifact_path)}.")
        end

        def listable_paths
          return [] unless all_entries

          all_entries.keys.map(&:to_s).reject { |path| path.end_with?('/') }.first(LISTED_PATHS_LIMIT)
        rescue StandardError
          []
        end

        def download_url
          ::Gitlab::Routing.url_helpers.download_project_job_artifacts_url(job.project, job)
        end

        def error(message)
          ::Mcp::Tools::Base::Response.error(message)
        end
      end
    end
  end
end

Mcp::Tools::Jobs::GetArtifactFileService.prepend_mod
