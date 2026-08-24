# frozen_string_literal: true

module Mcp
  module Tools
    module Jobs
      class GetJobService < Base::CustomService
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize

        INCLUDES = %w[log].freeze
        MAX_BYTE_LIMIT = ::Gitlab::Ci::Trace::Stream::LIMIT_SIZE
        MIN_BYTE_OFFSET = 0
        LOG_ALIAS = 'get_job_log'
        NOT_FOUND = 'Job not found or inaccessible'
        LOG_FORBIDDEN = "Job log not accessible: you do not have permission to read this job's log."

        register_version '0.1.0', {
          description: 'Get a CI/CD job in a GitLab project. Add include: log to also get the ' \
            "job's trace/log, which you can page through with byte_offset and byte_limit.",
          annotations: {
            readOnlyHint: true
          },
          input_schema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'ID or full path of the project'
              },
              job_id: {
                type: 'integer',
                description: 'ID of the job'
              },
              include: {
                type: 'array',
                description: 'Facet to include alongside the job, one per call: log.',
                items: {
                  type: 'string',
                  enum: INCLUDES
                },
                maxItems: 1
              },
              byte_offset: {
                type: 'integer',
                minimum: MIN_BYTE_OFFSET,
                description: "Byte offset to start reading the job's log from. Only applies when include is log. " \
                  "Default is #{MIN_BYTE_OFFSET}."
              },
              byte_limit: {
                type: 'integer',
                minimum: 1,
                maximum: MAX_BYTE_LIMIT,
                description: "Maximum number of bytes of the job's log to return. Only applies when include is " \
                  "log. Default and max is #{MAX_BYTE_LIMIT}."
              }
            },
            required: %w[id job_id]
          }
        }

        override :tool_aliases
        def self.tool_aliases
          # get_job_log only ever returned the log, with no `include` param. Calls made under
          # that name are treated as an implicit `include: log` so they keep returning it.
          [LOG_ALIAS]
        end

        # A job we cannot find and a job we cannot read get the same response, so the caller
        # cannot probe for jobs they have no access to.
        override :authorize!
        def authorize!(params)
          super
        rescue ::Gitlab::Access::AccessDeniedError
          raise ArgumentError, log_forbidden? ? LOG_FORBIDDEN : NOT_FOUND
        end

        protected

        def auth_ability
          include_log? ? :read_build_trace : :read_build
        end

        def auth_target(params)
          @arguments = params[:arguments] || {}
          @invoked_as = params[:name]

          job || raise(ArgumentError, NOT_FOUND)
        end

        def perform_default(arguments = {})
          @arguments = arguments || {}

          data = job_data
          data[:log] = log_facet if include_log?

          formatted_content = [{ type: 'text', text: Gitlab::Json.generate(data) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, data)
        end

        private

        attr_reader :arguments

        def job
          project = find_project!(arguments[:id])

          # The caller gives us a job ID only, so there is no partition_id to scope by. Same
          # lookup as `find_build!` in lib/api/helpers.rb, which backs GET /projects/:id/jobs/:job_id.
          # rubocop:disable Database/AvoidUnpartitionedCiRelations -- no partition key available
          project.builds.find_by_id(arguments[:job_id])
          # rubocop:enable Database/AvoidUnpartitionedCiRelations
        end
        strong_memoize_attr :job

        # A caller who can read the job already knows it exists, so naming the real reason the
        # log is off limits leaks nothing. The REST trace endpoint answers 403 here too.
        def log_forbidden?
          include_log? && ::Ability.allowed?(current_user, :read_build, job)
        end

        def include_log?
          @invoked_as == LOG_ALIAS || Array(arguments[:include]).include?('log')
        end

        def job_data
          {
            id: job.id,
            name: job.name,
            status: job.status,
            stage: job.stage,
            allow_failure: job.allow_failure,
            web_url: ::Gitlab::Routing.url_helpers.project_job_url(job.project, job)
          }
        end

        def log_facet
          byte_offset = arguments[:byte_offset] || MIN_BYTE_OFFSET
          byte_limit = arguments[:byte_limit] || MAX_BYTE_LIMIT

          total_bytes, content = job.trace.read do |stream|
            [stream.size || 0, stream.raw_range(byte_offset: byte_offset, byte_limit: byte_limit).to_s]
          end

          returned_start = [byte_offset, total_bytes].min
          returned_end = returned_start + content.bytesize
          truncated = returned_end < total_bytes

          system_instruction = if truncated
                                 "Log truncated. Remaining: #{total_bytes - returned_end} bytes. " \
                                   "Call again with {\"byte_offset\": #{returned_end}}."
                               end

          {
            metadata: {
              total_bytes: total_bytes,
              returned: { start: returned_start, end: returned_end },
              truncated: truncated
            },
            # A byte window can split a multi-byte character, so scrub before the response is
            # serialized to JSON, which rejects invalid UTF-8.
            content: content.scrub,
            system_instruction: system_instruction
          }.compact
        end
      end
    end
  end
end
