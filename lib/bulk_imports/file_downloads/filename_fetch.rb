# frozen_string_literal: true

module BulkImports
  module FileDownloads
    module FilenameFetch
      REMOTE_FILENAME_PATTERN = %r{filename="(?<filename>[^"]+)"}
      FILENAME_SIZE_LIMIT = 255 # chars before the extension

      def raise_error(message)
        raise NotImplementedError
      end

      private

      # Fetch the remote filename information from the request content-disposition header
      # - Raises if the filename does not exist
      # - If the filename is longer then 255 chars truncate it
      #   to be a total of 255 chars (with the extension)
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def remote_filename
        @remote_filename ||= begin
          pattern = BulkImports::FileDownloads::FilenameFetch::REMOTE_FILENAME_PATTERN
          name = response_headers['content-disposition'].to_s
            .match(pattern)                                # matches the filename pattern
            .then { |match| match&.named_captures || {} }  # ensures the match is a hash
            .fetch('filename')                             # fetches the 'filename' key or raise KeyError

          name = File.basename(name) # Ensures to remove path from the filename (../ for instance)
          ensure_filename_size(name) # Ensures the filename is within the FILENAME_SIZE_LIMIT
        end
      rescue KeyError
        raise_error 'Remote filename not provided in content-disposition header'
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def ensure_filename_size(filename)
        limit = BulkImports::FileDownloads::FilenameFetch::FILENAME_SIZE_LIMIT
        return filename if filename.length <= limit

        extname = File.extname(filename)
        basename = File.basename(filename, extname)[0, limit]
        "#{basename}#{extname}"
      end
    end
  end
end
