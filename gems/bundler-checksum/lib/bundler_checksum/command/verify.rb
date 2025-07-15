# frozen_string_literal: true

module BundlerChecksum::Command
  module Verify
    extend self

    def execute
      $stderr.puts 'Verifying bundle checksums'

      verified = true

      local_checksums.each do |gem|
        name = gem.fetch(:name)
        version = gem.fetch(:version)
        platform = gem.fetch(:platform)
        checksum = gem.fetch(:checksum)

        $stderr.puts "Verifying #{name}==#{version} #{platform}"
        unless validate_gem_checksum(name, version, platform, checksum)
          verified = false
        end
      end

      verified
    end

    private

    def local_checksums
      ::BundlerChecksum.checksums_from_file
    end

    def validate_gem_checksum(gem_name, gem_version, gem_platform, local_checksum)
      remote_checksums = Helper.remote_checksums_for_gem(gem_name, gem_version)
      if remote_checksums.empty?
        $stderr.puts "#{gem_name} #{gem_version} not found on Rubygems, skipping"
        return false
      end

      remote_platform_checksum = remote_checksums.find { |g| g[:name] == gem_name && g[:platform] == gem_platform.to_s }

      if local_checksum == remote_platform_checksum[:checksum]
        true
      else
        $stderr.puts "Gem #{gem_name} #{gem_version} #{gem_platform} failed checksum verification"
        $stderr.puts "LOCAL:  #{local_checksum}"
        $stderr.puts "REMOTE: #{remote_platform_checksum[:checksum]}"
        return false
      end
    end
  end
end
