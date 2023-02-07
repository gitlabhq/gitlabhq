# frozen_string_literal: true

module BulkImports
  module Pipeline
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize
    include Gitlab::ClassAttributes
    include Runner

    NotAllowedError = Class.new(StandardError)
    ExpiredError = Class.new(StandardError)
    FailedError = Class.new(StandardError)

    CACHE_KEY_EXPIRATION = 2.hours
    NDJSON_EXPORT_TIMEOUT = 90.minutes
    EMPTY_EXPORT_STATUS_TIMEOUT = 5.minutes

    def initialize(context)
      @context = context
    end

    def tracker
      @tracker ||= context.tracker
    end

    def portable
      @portable ||= context.portable
    end

    def import_export_config
      @import_export_config ||= context.import_export_config
    end

    def current_user
      @current_user ||= context.current_user
    end

    included do
      private

      attr_reader :context

      # Fetch pipeline extractor.
      # An extractor is defined either by instance `#extract(context)` method
      # or by using `extractor` DSL.
      #
      # @example
      # class MyPipeline
      #   extractor MyExtractor, foo: :bar
      # end
      #
      # class MyPipeline
      #   def extract(context)
      #     puts 'Fetch some data'
      #   end
      # end
      #
      # If pipeline implements instance method `extract` - use it
      # and ignore class `extractor` method implementation.
      def extractor
        @extractor ||= self.respond_to?(:extract) ? self : instantiate(self.class.get_extractor)
      end

      # Fetch pipeline transformers.
      #
      # A transformer can be defined using:
      #   - `transformer` class method
      #   - `transform` instance method
      #
      # Multiple transformers can be defined within a single
      # pipeline and run sequentially for each record in the
      # following order:
      #   - Instance method `transform`
      #   - Transformers defined using `transformer` class method
      #
      # Instance method `transform` is always the last to run.
      #
      # @example
      # class MyPipeline
      #   transformer MyTransformerOne, foo: :bar
      #   transformer MyTransformerTwo, foo: :bar
      #
      #   def transform(context, data)
      #     # perform transformation here
      #   end
      # end
      #
      # In the example above `#transform` is the first to run and
      # `MyTransformerTwo` method is the last.
      def transformers
        strong_memoize(:transformers) do
          defined_transformers = self.class.transformers.map(&method(:instantiate))

          transformers = []
          transformers << self if respond_to?(:transform)
          transformers.concat(defined_transformers)
          transformers
        end
      end

      # Fetch pipeline loader.
      # A loader is defined either by instance method `#load(context, data)`
      # or by using `loader` DSL.
      #
      # @example
      # class MyPipeline
      #   loader MyLoader, foo: :bar
      # end
      #
      # class MyPipeline
      #   def load(context, data)
      #     puts 'Load some data'
      #   end
      # end
      #
      # If pipeline implements instance method `load` - use it
      # and ignore class `loader` method implementation.
      def loader
        @loader ||= self.respond_to?(:load) ? self : instantiate(self.class.get_loader)
      end

      def pipeline
        @pipeline ||= self.class.name
      end

      def instantiate(class_config)
        options = class_config[:options]

        if options
          class_config[:klass].new(**class_config[:options])
        else
          class_config[:klass].new
        end
      end

      def abort_on_failure?
        self.class.abort_on_failure?
      end
    end

    class_methods do
      def extractor(klass, options = nil)
        class_attributes[:extractor] = { klass: klass, options: options }
      end

      def transformer(klass, options = nil)
        add_attribute(:transformers, klass, options)
      end

      def loader(klass, options = nil)
        class_attributes[:loader] = { klass: klass, options: options }
      end

      def get_extractor
        class_attributes[:extractor]
      end

      def transformers
        class_attributes[:transformers] || []
      end

      def get_loader
        class_attributes[:loader]
      end

      def abort_on_failure!
        class_attributes[:abort_on_failure] = true
      end

      def abort_on_failure?
        class_attributes[:abort_on_failure]
      end

      def file_extraction_pipeline!
        class_attributes[:file_extraction_pipeline] = true
      end

      def file_extraction_pipeline?
        class_attributes[:file_extraction_pipeline]
      end

      def relation_name(name)
        class_attributes[:relation_name] = name
      end

      def relation
        class_attributes[:relation_name] || default_relation
      end

      def default_relation
        self.name.demodulize.chomp('Pipeline').underscore
      end

      private

      def add_attribute(sym, klass, options)
        class_attributes[sym] ||= []
        class_attributes[sym] << { klass: klass, options: options }
      end
    end
  end
end
