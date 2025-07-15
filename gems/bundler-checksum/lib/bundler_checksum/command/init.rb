# frozen_string_literal: true

require 'openssl'

module BundlerChecksum::Command
  module Init
    extend self

    BUNDLER_2_5_0 = Gem::Version.new("2.5.0")
    BUNDLER_2_5_12 = Gem::Version.new("2.5.12")

    def execute
      $stderr.puts "Initializing checksum file #{checksum_file}"

      checksums = []

      require "bundler/vendored_uri"

      Bundler.definition.resolve.sort_by(&:name).each do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)
        spec_identifier = "#{spec.name}==#{spec.version}"

        previous_checksum = previous_checksums.select do |checksum|
          checksum[:name] == spec.name && checksum[:version] == spec.version.to_s
        end

        if !previous_checksum.empty?
          $stderr.puts "Using #{spec_identifier}"
          checksums += previous_checksum

          next
        end

        $stderr.puts "Adding #{spec_identifier}"

        compact_index_dependencies = compact_index_dependencies(spec.name).select { |item| item.first == spec.version.to_s }

        if !compact_index_dependencies.empty?
          compact_index_checksums = compact_index_dependencies.map do |version, platform, dependencies, requirements|
            {
              name: spec.name,
              version: spec.version.to_s,
              platform: Gem::Platform.new(platform).to_s,
              checksum: requirements.detect { |requirement| requirement.first == 'checksum' }.flatten[1]
            }
          end

          checksums += compact_index_checksums.sort_by { |hash| hash.values }
        else
          remote_checksum = Helper.remote_checksums_for_gem(spec.name, spec.version)

          if remote_checksum.empty?
            raise "#{spec.name} #{spec.version} not found on Rubygems!"
          end

          checksums += remote_checksum.sort_by { |hash| hash.values }
        end
      end

      File.write(checksum_file, JSON.generate(checksums, array_nl: "\n") + "\n")
    end

    private

    def compact_index_dependencies(name)
      if current_bundler_version >= BUNDLER_2_5_12
        compact_index_cache.dependencies([name])
      else
        compact_index_cache.dependencies(name)
      end
    end

    def compact_index_cache
      # RubyGems v3.5.6 got rid of Bundler::URI in favor of a vendored Gem::URI: https://github.com/rubygems/rubygems/pull/7386
      rubygems_source = 'https://rubygems.org'
      remote_uri = defined?(Gem::URI) ? Gem::URI(rubygems_source) : Bundler::URI(rubygems_source)
      remote = Bundler::Source::Rubygems::Remote.new(remote_uri)
      # Constructor changed with https://github.com/rubygems/rubygems/pull/7678/
      @compact_index_cache ||= if current_bundler_version >= BUNDLER_2_5_12
                                 cache_path = Bundler.user_cache.join("compact_index", remote.cache_slug)
                                 Bundler::CompactIndexClient.new(cache_path)
                               else
                                 args = [nil, remote, nil]
                                 # gem_remote_fetcher added in https://github.com/rubygems/rubygems/pull/7092/
                                 args << nil if current_bundler_version >= BUNDLER_2_5_0
                                 Bundler::Fetcher::CompactIndex
                                                   .new(*args)
                                                   .send(:compact_index_client)
                                                   .instance_variable_get(:@cache)
                               end
    end

    def current_bundler_version
      @bundler_version ||= Gem::Version.new(Bundler::VERSION)
    end

    def previous_checksums
      @previous_checksums ||=
        if File.exist?(checksum_file)
          ::BundlerChecksum.checksums_from_file
        else
          []
        end
    end

    def checksum_file
      ::BundlerChecksum.checksum_file
    end

    def lockfile
      lockfile_path = Bundler.default_lockfile
      lockfile = Bundler::LockfileParser.new(Bundler.read_file(lockfile_path))
    end
  end
end
