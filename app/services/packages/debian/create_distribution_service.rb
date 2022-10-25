# frozen_string_literal: true

module Packages
  module Debian
    class CreateDistributionService
      def initialize(container, user, params)
        @container = container
        @params = params
        @params[:creator] = user

        @components = params.delete(:components) || ['main']

        @architectures = params.delete(:architectures) || ['amd64']
        @architectures += ['all']

        @distribution = nil
        @errors = []
      end

      def execute
        create_distribution
      end

      private

      attr_reader :container, :params, :components, :architectures, :distribution, :errors

      def append_errors(record, prefix = '')
        return if record.valid?

        prefix = "#{prefix} " unless prefix.empty?
        @errors += record.errors.full_messages.map { |message| "#{prefix}#{message}" }
      end

      def create_distribution
        @distribution = container.debian_distributions.new(params)

        append_errors(distribution)
        return error unless errors.empty?

        result = distribution.transaction do
          next unless distribution.save

          create_components
          create_architectures
          success
        end

        result ||= error

        ::Packages::Debian::GenerateDistributionWorker.perform_async(distribution.class.container_type, distribution.reset.id) if result.success?

        result
      end

      def create_components
        create_objects(distribution.components, components, error_label: 'Component')
      end

      def create_architectures
        create_objects(distribution.architectures, architectures, error_label: 'Architecture')
      end

      def create_objects(objects, object_names_from_params, error_label:)
        object_names_from_params.each do |name|
          new_object = objects.create(name: name)
          append_errors(new_object, error_label)
          raise ActiveRecord::Rollback unless new_object.persisted?
        end
      end

      def success
        ServiceResponse.success(payload: { distribution: distribution }, http_status: :created)
      end

      def error
        ServiceResponse.error(message: errors.to_sentence, payload: { distribution: distribution })
      end
    end
  end
end
