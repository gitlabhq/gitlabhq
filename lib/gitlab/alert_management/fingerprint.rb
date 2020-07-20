# frozen_string_literal: true

module Gitlab
  module AlertManagement
    class Fingerprint
      def self.generate(data)
        new.generate(data)
      end

      def generate(data)
        return unless data.present?

        string = case data
                 when Array then flatten_array(data)
                 when Hash then flatten_hash(data)
                 else
                   data.to_s
                 end

        Digest::SHA1.hexdigest(string)
      end

      private

      def flatten_array(array)
        array.flatten.map!(&:to_s).join
      end

      def flatten_hash(hash)
        # Sort hash so SHA generated is the same
        Gitlab::Utils::SafeInlineHash.merge_keys!(hash).sort.to_s
      end
    end
  end
end
