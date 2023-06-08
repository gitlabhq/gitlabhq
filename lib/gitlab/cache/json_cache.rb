# frozen_string_literal: true

module Gitlab
  module Cache
    class JsonCache
      STRATEGY_KEY_COMPONENTS = {
        revision: Gitlab.revision,
        version: [Gitlab::VERSION, Rails.version]
      }.freeze

      def initialize(options = {})
        @backend = options.fetch(:backend, Rails.cache)
        @namespace = options.fetch(:namespace, nil)
        @cache_key_strategy = options.fetch(:cache_key_strategy, :revision)
      end

      def active?
        if backend.respond_to?(:active?)
          backend.active?
        else
          true
        end
      end

      def expire(key)
        backend.delete(cache_key(key))
      end

      def read(key, klass = nil)
        value = read_raw(key)
        value = parse_value(value, klass) unless value.nil?
        value
      end

      def write(key, value, options = nil)
        write_raw(key, value, options)
      end

      def fetch(key, options = {})
        klass = options.delete(:as)
        value = read(key, klass)

        return value unless value.nil?

        value = yield

        write(key, value, options)

        value
      end

      private

      attr_reader :backend, :namespace, :cache_key_strategy

      def cache_key(key)
        expanded_cache_key(key).compact.join(':').freeze
      end

      def write_raw(_key, _value, _options)
        raise NoMethodError
      end

      def expanded_cache_key(_key)
        raise NoMethodError
      end

      def read_raw(_key)
        raise NoMethodError
      end

      def parse_value(value, klass)
        case value
        when Hash then parse_entry(value, klass)
        when Array then parse_entries(value, klass)
        else
          value
        end
      end

      def parse_entry(raw, klass)
        return unless valid_entry?(raw, klass)
        return klass.new(raw) unless klass.ancestors.include?(ActiveRecord::Base)

        # When the cached value is a persisted instance of ActiveRecord::Base in
        # some cases a relation can return an empty collection because scope.none!
        # is being applied on ActiveRecord::Associations::CollectionAssociation#scope
        # when the new_record? method incorrectly returns false.
        #
        # See https://gitlab.com/gitlab-org/gitlab/issues/9903#note_145329964
        klass.allocate.init_with(encode_for(klass, raw))
      end

      def encode_for(klass, raw)
        # We have models that leave out some fields from the JSON export for
        # security reasons, e.g. models that include the CacheMarkdownField.
        # The ActiveRecord::AttributeSet we build from raw does know about
        # these columns so we need manually set them.
        missing_attributes = (klass.columns.map(&:name) - raw.keys)
        missing_attributes.each { |column| raw[column] = nil }

        coder = {}
        klass.new(raw).encode_with(coder)
        coder["new_record"] = new_record?(raw, klass)
        coder
      end

      def new_record?(raw, klass)
        raw.fetch(klass.primary_key, nil).blank?
      end

      def valid_entry?(raw, klass)
        return false unless klass && raw.is_a?(Hash)

        (raw.keys - klass.attribute_names).empty?
      end

      def parse_entries(values, klass)
        values.filter_map { |value| parse_entry(value, klass) }
      end
    end
  end
end
