# frozen_string_literal: true

module Packages
  module Debian
    class DestroyDistributionService
      def initialize(distribution)
        @distribution = distribution
      end

      def execute
        destroy_distribution
      end

      private

      def destroy_distribution
        if @distribution.destroy
          success
        else
          error("Unable to destroy Debian #{@distribution.model_name.human.downcase}")
        end
      end

      def success
        ServiceResponse.success
      end

      def error(message)
        ServiceResponse.error(message: message, payload: { distribution: @distribution })
      end
    end
  end
end
