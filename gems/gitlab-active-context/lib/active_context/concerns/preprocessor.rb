# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Preprocessor
      def preprocessors
        @preprocessors ||= []
      end

      def add_preprocessor(name, &block)
        preprocessors << { name: name, block: block }
      end

      def preprocess(refs)
        result = { successful: [], failed: [] }

        refs_by_class = refs.group_by(&:class)

        refs_by_class.each do |klass, class_refs|
          all_failed_refs = []
          current_successful_refs = class_refs

          klass.preprocessors.each do |preprocessor|
            next if current_successful_refs.empty?

            processed = preprocessor[:block].call(current_successful_refs)

            all_failed_refs.concat(processed[:failed])
            current_successful_refs = processed[:successful]
          end

          result[:successful].concat(current_successful_refs)
          result[:failed].concat(all_failed_refs)
        end

        result
      end

      def with_per_ref_handling(refs, retry_error_types: [StandardError], skip_error_types: [])
        return { successful: [], failed: [] } unless refs.any?

        failed_refs = []
        successful_refs = []

        refs.each do |ref|
          yield(ref)
          successful_refs << ref
        rescue *skip_error_types => e
          ::ActiveContext::Logger.skippable_exception(
            e, class: self.class.name, reference: ref.serialize, reference_id: ref.identifier
          )
        rescue *retry_error_types => e
          ::ActiveContext::Logger.retryable_exception(
            e, class: self.class.name, reference: ref.serialize, reference_id: ref.identifier
          )

          failed_refs << ref
        end

        { successful: successful_refs, failed: failed_refs }
      end

      def with_batch_handling(refs, error_types: [StandardError])
        return { successful: [], failed: [] } unless refs.any?

        begin
          yield(refs)

          { successful: refs, failed: [] }
        rescue *error_types => e
          ::ActiveContext::Logger.retryable_exception(e, class: self.class.name, refs: refs.map(&:serialize))

          { successful: [], failed: refs }
        end
      end
    end
  end
end
