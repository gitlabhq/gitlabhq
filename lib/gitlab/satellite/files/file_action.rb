module Gitlab
  module Satellite
    class FileAction < Action
      attr_accessor :file_path, :ref

      def initialize(user, project, ref, file_path)
        super user, project
        @file_path = file_path
        @ref = ref
      end

      def safe_path?(path)
        File.absolute_path(path) == path
      end

      def write_file(abs_file_path, content, file_encoding = 'text')
		if file_encoding == 'base64'
			 File.open(abs_file_path, 'wb') { |f| f.write(Base64.encode64(content))}
		else
			 enc_64=Base64.encode64(content)
			 File.open(abs_file_path, 'wb') { |f| f.write(Base64.decode64(enc_64))} 
        end
      end
    end
  end
end
