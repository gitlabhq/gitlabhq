# frozen_string_literal: true

module Gitlab
  module AlertManagement
    class Fingerprint
      def self.generate(data)
        new.generate(data)
      end

      def generate(data)
        return unless data.present?

        if data.is_a?(Array)
          data = flatten_array(data)
        end

        Digest::SHA1.hexdigest(data.to_s)
      end

      private

      def flatten_array(array)
        array.flatten.map!(&:to_s).join
      end
    end
  end
end
