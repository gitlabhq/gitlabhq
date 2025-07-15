# frozen_string_literal: true

require 'bundler'
require 'bundler_checksum/version'
require 'json'

module Bundler
  module Patches
    # This module monkey-patches Bundler to check Gemfile.checksum
    # when installing gems that are from RubyGems
    module RubyGemsInstallerPatch
      def pre_install_checks
        super && validate_local_package_checksum
      end

      private

      def validate_local_package_checksum
        cached_checksum = fetch_checksum_from_file(spec)

        if cached_checksum.nil?
          raise SecurityError, "Cached checksum for #{spec.full_name} not found. Please (re-)generate Gemfile.checksum with " \
            "`bundle exec bundler-checksum init`. See https://docs.gitlab.com/ee/development/gemfile.html#updating-the-checksum-file."
        end

        validate_file_checksum(cached_checksum)
      end

      def fetch_checksum_from_file(spec)
        ::BundlerChecksum.checksum_for(spec.name, spec.version.to_s, spec.platform.to_s)
      end

      # Modified from
      # https://github.com/rubygems/rubygems/blob/243173279e79a38f03e318eea8825d1c8824e119/bundler/lib/bundler/rubygems_gem_installer.rb#L116
      def validate_file_checksum(checksum)
        return true if Bundler.settings[:disable_checksum_validation]

        source = @package.instance_variable_get(:@gem)

        # Contary to upstream, we raise instead of silently returning
        raise "#{@package.inspect} does not have :@gem" unless source
        raise "#{source.inspect} does not respond to :with_read_io" unless source.respond_to?(:with_read_io)

        digest =
          if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new("2.5.0")
            gem_checksum.digest
          else
            source.with_read_io do |io|
              digest = SharedHelpers.digest(:SHA256).new
              digest << io.read(16_384) until io.eof?
              io.rewind
              send(checksum_type(checksum), digest)
            end
          end

        unless digest == checksum
          raise SecurityError, <<-MESSAGE
          Bundler cannot continue installing #{spec.name} (#{spec.version}).
          The checksum for the downloaded `#{spec.full_name}.gem` does not match \
          the checksum from the checksum file. This means the contents of the downloaded \
          gem is different from what was recorded in the checksum file, and could be potential security issue.
          gem is different from what was uploaded to the server, and could be a potential security issue.

          To resolve this issue:
          1. delete the downloaded gem located at: `#{spec.gem_dir}/#{spec.full_name}.gem`
          2. run `bundle install`

          If you wish to continue installing the downloaded gem, and are certain it does not pose a \
          security issue despite the mismatching checksum, do the following:
          1. run `bundle config set --local disable_checksum_validation true` to turn off checksum verification
          2. run `bundle install`

          (More info: The expected SHA256 checksum was #{checksum.inspect}, but the \
          checksum for the downloaded gem was #{digest.inspect}.)
          MESSAGE
        end
        true
      end
    end
  end
end

module BundlerChecksum
  class << self
    def checksum_file
      @checksum_file ||= "#{Bundler.default_gemfile}.checksum"
    end

    def checksums_from_file
      @checksums_from_file ||= JSON.parse(File.open(checksum_file).read, symbolize_names: true)
    rescue JSON::ParserError => e
      raise "Invalid checksum file: #{e.message}"
    end

    def checksum_for(gem_name, gem_version, gem_platform)
      item = checksums_from_file.detect do |item|
        item[:name] == gem_name &&
          item[:platform] == gem_platform &&
          item[:version] == gem_version
      end

      item&.fetch(:checksum)
    end

    def patch!
      return if defined?(@patched) && @patched
      @patched = true

      Bundler.ui.info "Patching bundler with bundler-checksum..."
      require 'bundler/rubygems_gem_installer'
      ::Bundler::RubyGemsGemInstaller.prepend(Bundler::Patches::RubyGemsInstallerPatch)
    end
  end
end
