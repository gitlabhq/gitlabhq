module Gitlab
  class PagesClient
    class << self
      attr_reader :certificate, :token

      def call(service, rpc, request, timeout: nil)
        kwargs = request_kwargs(timeout)
        stub(service).__send__(rpc, request, kwargs) # rubocop:disable GitlabSecurity/PublicSend
      end

      # This function is not thread-safe. Call it from an initializer only.
      def read_or_create_token
        @token = read_token
      rescue Errno::ENOENT
        # TODO: uncomment this when omnibus knows how to write the token file for us
        # https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2466
        #
        # write_token(SecureRandom.random_bytes(64))
        #
        # # Read from disk in case someone else won the race and wrote the file
        # # before us. If this fails again let the exception bubble up.
        # @token = read_token
      end

      # This function is not thread-safe. Call it from an initializer only.
      def load_certificate
        cert_path = config.certificate
        return unless cert_path.present?

        @certificate = File.read(cert_path)
      end

      def ping
        request = Grpc::Health::V1::HealthCheckRequest.new
        call(:health_check, :check, request, timeout: 5.seconds)
      end

      private

      def request_kwargs(timeout)
        encoded_token = Base64.strict_encode64(token.to_s)
        metadata = {
          'authorization' => "Bearer #{encoded_token}"
        }

        result = { metadata: metadata }

        return result unless timeout

        # Do not use `Time.now` for deadline calculation, since it
        # will be affected by Timecop in some tests, but grpc's c-core
        # uses system time instead of timecop's time, so tests will fail
        # `Time.at(Process.clock_gettime(Process::CLOCK_REALTIME))` will
        # circumvent timecop
        deadline = Time.at(Process.clock_gettime(Process::CLOCK_REALTIME)) + timeout
        result[:deadline] = deadline

        result
      end

      def stub(name)
        stub_class(name).new(address, grpc_creds)
      end

      def stub_class(name)
        if name == :health_check
          Grpc::Health::V1::Health::Stub
        else
          # TODO use pages namespace
          Gitaly.const_get(name.to_s.camelcase.to_sym).const_get(:Stub)
        end
      end

      def address
        addr = config.address
        addr = addr.sub(%r{^tcp://}, '') if URI(addr).scheme == 'tcp'
        addr
      end

      def grpc_creds
        if address.start_with?('unix:')
          :this_channel_is_insecure
        elsif @certificate
          GRPC::Core::ChannelCredentials.new(@certificate)
        else
          # Use system certificate pool
          GRPC::Core::ChannelCredentials.new
        end
      end

      def config
        Gitlab.config.pages.admin
      end

      def read_token
        File.read(token_path)
      end

      def token_path
        Rails.root.join('.gitlab_pages_secret').to_s
      end

      def write_token(new_token)
        Tempfile.open(File.basename(token_path), File.dirname(token_path),  encoding: 'ascii-8bit') do |f|
          f.write(new_token)
          f.close
          File.link(f.path, token_path)
        end
      rescue Errno::EACCES => ex
        # TODO stop rescuing this exception in GitLab 11.0 https://gitlab.com/gitlab-org/gitlab-ce/issues/45672
        Rails.logger.error("Could not write pages admin token file: #{ex}")
      rescue Errno::EEXIST
        # Another process wrote the token file concurrently with us. Use their token, not ours.
      end
    end
  end
end
