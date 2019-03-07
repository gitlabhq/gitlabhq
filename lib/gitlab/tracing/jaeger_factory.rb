# frozen_string_literal: true

require 'jaeger/client'

module Gitlab
  module Tracing
    class JaegerFactory
      # When the probabilistic sampler is used, by default 0.1% of requests will be traced
      DEFAULT_PROBABILISTIC_RATE = 0.001

      # The default port for the Jaeger agent UDP listener
      DEFAULT_UDP_PORT = 6831

      # Reduce this from default of 10 seconds as the Ruby jaeger
      # client doesn't have overflow control, leading to very large
      # messages which fail to send over UDP (max packet = 64k)
      # Flush more often, with smaller packets
      FLUSH_INTERVAL = 5

      def self.create_tracer(service_name, options)
        kwargs = {
          service_name: service_name,
          sampler: get_sampler(options[:sampler], options[:sampler_param]),
          reporter: get_reporter(service_name, options[:http_endpoint], options[:udp_endpoint])
        }.compact

        extra_params = options.except(:sampler, :sampler_param, :http_endpoint, :udp_endpoint, :strict_parsing, :debug) # rubocop: disable CodeReuse/ActiveRecord
        if extra_params.present?
          message = "jaeger tracer: invalid option: #{extra_params.keys.join(", ")}"

          if options[:strict_parsing]
            raise message
          else
            warn message
          end
        end

        Jaeger::Client.build(kwargs)
      end

      def self.get_sampler(sampler_type, sampler_param)
        case sampler_type
        when "probabilistic"
          sampler_rate = sampler_param ? sampler_param.to_f : DEFAULT_PROBABILISTIC_RATE
          Jaeger::Samplers::Probabilistic.new(rate: sampler_rate)
        when "const"
          const_value = sampler_param == "1"
          Jaeger::Samplers::Const.new(const_value)
        else
          nil
        end
      end
      private_class_method :get_sampler

      def self.get_reporter(service_name, http_endpoint, udp_endpoint)
        encoder = Jaeger::Encoders::ThriftEncoder.new(service_name: service_name)

        if http_endpoint.present?
          sender = get_http_sender(encoder, http_endpoint)
        elsif udp_endpoint.present?
          sender = get_udp_sender(encoder, udp_endpoint)
        else
          return
        end

        Jaeger::Reporters::RemoteReporter.new(
          sender: sender,
          flush_interval: FLUSH_INTERVAL
        )
      end
      private_class_method :get_reporter

      def self.get_http_sender(encoder, address)
        Jaeger::HttpSender.new(
          url: address,
          encoder: encoder,
          logger: Logger.new(STDOUT)
        )
      end
      private_class_method :get_http_sender

      def self.get_udp_sender(encoder, address)
        pair = address.split(":", 2)
        host = pair[0]
        port = pair[1] ? pair[1].to_i : DEFAULT_UDP_PORT

        Jaeger::UdpSender.new(
          host: host,
          port: port,
          encoder: encoder,
          logger: Logger.new(STDOUT)
        )
      end
      private_class_method :get_udp_sender
    end
  end
end
