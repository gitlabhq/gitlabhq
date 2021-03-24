# frozen_string_literal: true

module Packages
  module Debian
    class FileEntry
      include ActiveModel::Model

      DIGESTS = %i[md5 sha1 sha256].freeze
      FILENAME_REGEX = %r{\A[a-zA-Z0-9][a-zA-Z0-9_.~+-]*\z}.freeze

      attr_accessor :filename,
                    :size,
                    :md5sum,
                    :section,
                    :priority,
                    :sha1sum,
                    :sha256sum,
                    :package_file

      validates :filename, :size, :md5sum, :section, :priority, :sha1sum, :sha256sum, :package_file, presence: true
      validates :filename, format: { with: FILENAME_REGEX }
      validate :valid_package_file_digests, if: -> { md5sum.present? && sha1sum.present? && sha256sum.present? && package_file.present? }

      def component
        return 'main' if section.blank?
        return 'main' unless section.include?('/')

        section.split('/')[0]
      end

      private

      def valid_package_file_digests
        DIGESTS.each do |digest|
          package_file_digest = package_file["file_#{digest}"]
          sum = public_send("#{digest}sum") # rubocop:disable GitlabSecurity/PublicSend
          next if package_file_digest == sum

          errors.add("#{digest}sum".to_sym, "mismatch for #{filename}: #{package_file_digest} != #{sum}")
        end
      end
    end
  end
end
