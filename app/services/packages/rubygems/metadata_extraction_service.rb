# frozen_string_literal: true

module Packages
  module Rubygems
    class MetadataExtractionService
      def initialize(package, gemspec)
        @package = package
        @gemspec = gemspec
      end

      def execute
        write_metadata
      end

      private

      attr_reader :package, :gemspec

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def write_metadata
        metadatum.update!(
          authors: gemspec&.authors,
          files: gemspec&.files&.to_json,
          summary: gemspec&.summary,
          description: gemspec&.description,
          email: gemspec&.email,
          homepage: gemspec&.homepage,
          licenses: gemspec&.licenses&.to_json,
          metadata: gemspec&.metadata&.to_json,
          author: gemspec&.author,
          bindir: gemspec&.bindir,
          executables: gemspec&.executables&.to_json,
          extensions: gemspec&.extensions&.to_json,
          extra_rdoc_files: gemspec&.extra_rdoc_files&.to_json,
          platform: gemspec&.platform,
          post_install_message: gemspec&.post_install_message,
          rdoc_options: gemspec&.rdoc_options&.to_json,
          require_paths: gemspec&.require_paths&.to_json,
          required_ruby_version: gemspec&.required_ruby_version&.to_s,
          required_rubygems_version: gemspec&.required_rubygems_version&.to_s,
          requirements: gemspec&.requirements&.to_json,
          rubygems_version: gemspec&.rubygems_version
        )
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity

      def metadatum
        # safe_find_or_create_by! was originally called here.
        # We merely switched to `find_or_create_by!`
        # rubocop: disable CodeReuse/ActiveRecord
        Packages::Rubygems::Metadatum.find_or_create_by!(package: package)
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
