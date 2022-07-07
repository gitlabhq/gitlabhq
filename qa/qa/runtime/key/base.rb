# frozen_string_literal: true

module QA
  module Runtime
    module Key
      class Base
        attr_reader :name, :bits, :private_key, :public_key, :md5_fingerprint, :sha256_fingerprint

        def initialize(name, bits)
          @name = name
          @bits = bits

          Dir.mktmpdir do |dir|
            path = "#{dir}/id_#{name}"

            ssh_keygen(name, bits, path)
            populate_key_data(path)
          end
        end

        private

        def ssh_keygen(name, bits, path)
          cmd = %W[ssh-keygen -t #{name} -b #{bits} -f #{path} -N] << ''

          Service::Shellout.shell(cmd)
        end

        def fingerprint(path, hash_alg)
          `ssh-keygen -l -E #{hash_alg} -f #{path} | cut -d' ' -f2 | cut -d: -f2-`.chomp
        end

        def populate_key_data(path)
          @private_key = ::File.binread(path)
          @public_key = ::File.binread("#{path}.pub")
          @md5_fingerprint = fingerprint(path, :md5)
          @sha256_fingerprint = fingerprint(path, :sha256)
        end
      end
    end
  end
end
