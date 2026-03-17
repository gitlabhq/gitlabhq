# frozen_string_literal: true

require 'digest'

module Gitlab
  module GrapeOpenapi
    class RequestBodyRegistry
      SCHEMA_PATH_PREFIX = '#/components/schemas/'

      attr_reader :schemas

      def initialize
        @schemas = {}
        @schema_hashes = {}
      end

      def register(schema)
        return nil if schema.blank?

        schema_hash = compute_hash(schema)

        if @schema_hashes.key?(schema_hash)
          existing_name = @schema_hashes[schema_hash]
          return { '$ref' => "#{SCHEMA_PATH_PREFIX}#{existing_name}" }
        end

        name = "RequestBody_#{short_hash(schema_hash)}"
        @schemas[name] = schema
        @schema_hashes[schema_hash] = name

        { '$ref' => "#{SCHEMA_PATH_PREFIX}#{name}" }
      end

      private

      def compute_hash(schema)
        normalized = normalize_for_hash(schema)
        OpenSSL::Digest::SHA256.hexdigest(normalized.to_s)
      end

      def short_hash(full_hash)
        full_hash[0, 12]
      end

      def normalize_for_hash(obj)
        case obj
        when Hash
          obj.sort.map { |k, v| [k.to_s, normalize_for_hash(v)] }
        when Array
          obj.map { |v| normalize_for_hash(v) }
        else
          obj
        end
      end
    end
  end
end
