# frozen_string_literal: true

module Packages
  module Debian
    class UpdateDistributionService
      def initialize(distribution, params)
        @distribution = distribution
        @params = params

        @components = params.delete(:components)

        @architectures = params.delete(:architectures)
        @architectures += ['all'] unless @architectures.nil?

        @errors = []
      end

      def execute
        update_distribution
      end

      private

      attr_reader :distribution, :params, :components, :architectures, :errors

      def append_errors(record, prefix = '')
        return if record.valid?

        prefix = "#{prefix} " unless prefix.empty?
        @errors += record.errors.full_messages.map { |message| "#{prefix}#{message}" }
      end

      def update_distribution
        result = distribution.transaction do
          if distribution.update(params)
            update_components if components
            update_architectures if architectures

            success
          else
            append_errors(distribution)
            error
          end
        end

        result ||= error

        ::Packages::Debian::GenerateDistributionWorker.perform_async(distribution.class.container_type, distribution.id) if result.success?

        result
      end

      def update_components
        update_objects(distribution.components, components, error_label: 'Component')
      end

      def update_architectures
        update_objects(distribution.architectures, architectures, error_label: 'Architecture')
      end

      def update_objects(objects, object_names_from_params, error_label:)
        current_object_names = objects.map(&:name)
        missing_object_names = object_names_from_params - current_object_names
        extra_object_names = current_object_names - object_names_from_params

        missing_object_names.each do |name|
          new_object = objects.create(name: name)
          append_errors(new_object, error_label)
          raise ActiveRecord::Rollback unless new_object.persisted?
        end

        extra_object_names.each do |name|
          object = objects.with_name(name).first
          raise ActiveRecord::Rollback unless object.destroy
        end
      end

      def success
        ServiceResponse.success(payload: { distribution: distribution })
      end

      def error
        ServiceResponse.error(message: errors.to_sentence, payload: { distribution: distribution })
      end
    end
  end
end
