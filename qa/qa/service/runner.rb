module QA
  module Service
    class Runner
      include Scenario::Actable
      include Service::Shellout

      def initialize(image)
        @image = image
      end

      def pull
        shell "docker pull #{@image}"
      end

      def register(token)
        raise NotImplementedError
      end

      def run
        raise NotImplementedError
      end

      def remove
        raise NotImplementedError
      end
    end
  end
end
