# frozen_string_literal: true

module Gitlab
  module Repositories
    class LargeMultipartParser < Rack::Multipart::Parser
      # Replicates Rack::Multipart.extract_multipart from Rack 2.2.23:
      # https://github.com/rack/rack/blob/f2af0c8f869193fa7bb7d20b619b3003418e1055/lib/rack/multipart.rb#L39
      # Overriding parse_multipart ensures our subclass is instantiated during
      # parsing so that update_retained_size enforces our higher size limit.
      def self.parse_multipart(env, params = Rack::Utils.default_query_parser)
        req = Rack::Request.new(env)
        io = req.get_header(Rack::RACK_INPUT)
        io.rewind
        content_length = req.content_length
        content_length = content_length.to_i if content_length

        tempfile = req.get_header(Rack::RACK_MULTIPART_TEMPFILE_FACTORY) || TEMPFILE_FACTORY
        bufsize = req.get_header(Rack::RACK_MULTIPART_BUFFER_SIZE) || BUFSIZE

        info = parse(io, content_length, req.get_header('CONTENT_TYPE'), tempfile, bufsize, params)
        # Rack 2.2.23 sets RACK_TEMPFILES so temporary files created during
        # parsing are tracked and can be cleaned up after the request.
        req.set_header(Rack::RACK_TEMPFILES, info.tmp_files)
        info.params
      end

      private

      def update_retained_size(size)
        @retained_size += size

        return if @retained_size <= ::Repositories::CommitsUploader.max_request_size

        raise EOFError, 'multipart data over retained size limit'
      end
    end
  end
end
