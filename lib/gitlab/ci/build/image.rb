# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Image
        attr_reader :alias, :command, :entrypoint, :name, :ports

        class << self
          def from_image(job)
            image = Gitlab::Ci::Build::Image.new(job.options[:image])
            return unless image.valid?

            image
          end

          def from_services(job)
            services = job.options[:services].to_a.map do |service|
              Gitlab::Ci::Build::Image.new(service)
            end

            services.select(&:valid?).compact
          end
        end

        def initialize(image)
          if image.is_a?(String)
            @name = image
            @ports = []
          elsif image.is_a?(Hash)
            @alias = image[:alias]
            @command = image[:command]
            @entrypoint = image[:entrypoint]
            @name = image[:name]
            @ports = build_ports(image).select(&:valid?)
          end
        end

        def valid?
          @name.present?
        end

        private

        def build_ports(image)
          image[:ports].to_a.map { |port| ::Gitlab::Ci::Build::Port.new(port) }
        end
      end
    end
  end
end
