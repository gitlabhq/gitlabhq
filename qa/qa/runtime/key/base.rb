module QA
  module Runtime
    module Key
      class Base
        attr_reader :private_key, :public_key, :fingerprint

        def initialize(name, bits)
          Dir.mktmpdir do |dir|
            path = "#{dir}/id_#{name}"

            ssh_keygen(name, bits, path)
            populate_key_data(path)
          end
        end

        private

        def ssh_keygen(name, bits, path)
          cmd = %W[ssh-keygen -t #{name} -b #{bits} -f #{path} -N] << ''

          IO.popen([*cmd, err: %i[child out]]) do |io|
            out = io.read
            io.close

            raise "ssh-keygen failed with output: #{out}" unless $?.success?
          end
        end

        def populate_key_data(path)
          @private_key = File.binread(path)
          @public_key = File.binread("#{path}.pub")
          @fingerprint =
            `ssh-keygen -l -E md5 -f #{path} | cut -d' ' -f2 | cut -d: -f2-`.chomp
        end
      end
    end
  end
end
