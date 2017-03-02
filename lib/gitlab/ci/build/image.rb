module Gitlab
  module Ci
    module Build
      class Image
        attr_reader :name

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
          type = image.class
          @name = image if type == String
        end

        def valid?
          @name.present?
        end
      end
    end
  end
end
