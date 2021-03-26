# frozen_string_literal: true

module Packages
  module Rubygems
    class CreateGemspecService
      def initialize(package, gemspec)
        @package = package
        @gemspec = gemspec
      end

      def execute
        write_gemspec_to_file
      end

      private

      attr_reader :package, :gemspec

      def write_gemspec_to_file
        file = Tempfile.new

        begin
          content = gemspec.to_ruby
          file.write(content)
          file.flush

          package.package_files.create!(
            file: file,
            size: file.size,
            file_name: "#{gemspec.name}.gemspec",
            file_sha1: Digest::SHA1.hexdigest(content),
            file_md5: Digest::MD5.hexdigest(content),
            file_sha256: Digest::SHA256.hexdigest(content)
          )
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
