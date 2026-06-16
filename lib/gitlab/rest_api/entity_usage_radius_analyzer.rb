# frozen_string_literal: true

module Gitlab
  module RestApi
    class EntityUsageRadiusAnalyzer
      THRESHOLD = 15

      # Mirrors the cop's Include globs in .rubocop.yml for API/EntityExposureGrowth:
      # 'lib/**/api/entities/**/*.rb' and 'ee/lib/**/api/entities/**/*.rb'.
      # Only entities the cop can actually inspect are worth reporting.
      COP_SCOPE_PATTERN = %r{\A(ee/)?lib/(.+/)?api/entities/.+\.rb\z}

      def self.entity_file_path(entity_class)
        location = Object.const_source_location(entity_class.name)
        return unless location

        file_path = location.first
        return unless file_path

        Pathname.new(file_path).relative_path_from(Rails.root).to_s
      rescue TypeError, NameError
        nil
      end

      def self.extract_field_names(file_path)
        require 'rubocop'

        full_path = Rails.root.join(file_path)
        return [] unless File.exist?(full_path)

        source = RuboCop::ProcessedSource.new(File.read(full_path), RUBY_VERSION.to_f, full_path.to_s)
        return [] unless source.valid_syntax?

        # Does not pick up EE prepend_mod_with overrides; verify manually for entities with EE extensions.
        field_names = []
        source.ast.each_descendant(:send, :csend) do |node|
          next unless node.method_name == :expose

          syms = node.arguments.select(&:sym_type?).map { |a| a.value.to_s }
          field_names.concat(syms)
        end

        field_names
      end

      def self.extract_entity_classes(value)
        case value
        when Class then [value]
        when Hash then [value[:model], value[:entity]].compact.select { |v| v.is_a?(Class) }
        when Array then value.flat_map { |v| extract_entity_classes(v) }
        else []
        end
      end

      def self.collect_using_classes(exposures)
        exposures.flat_map do |exposure|
          using_class = begin
            exposure.respond_to?(:using_class) ? exposure.using_class : nil
          rescue StandardError
            nil
          end

          nested = exposure.respond_to?(:nested_exposures) ? exposure.nested_exposures : []

          [using_class].compact + collect_using_classes(nested)
        end
      end

      def initialize
        @direct_endpoint_counts = {}
        @reverse_dependencies = Hash.new { |h, k| h[k] = Set.new }
      end

      def high_impact_entities
        build_direct_endpoint_map
        build_reverse_dependency_graph
        compute_usage_radii.select do |entity, radius|
          radius >= THRESHOLD && cop_scoped?(entity)
        end
      end

      private

      def cop_scoped?(entity)
        path = self.class.entity_file_path(entity)
        path&.match?(COP_SCOPE_PATTERN)
      end

      def build_direct_endpoint_map
        routes = ::Gitlab::RequestEndpoints.all_api_endpoints

        routes.each do |route|
          entity_value = route.options[:entity]
          next unless entity_value

          self.class.extract_entity_classes(entity_value).each do |entity|
            next unless entity < Grape::Entity
            next unless entity.name.present?

            @direct_endpoint_counts[entity] ||= 0
            @direct_endpoint_counts[entity] += 1
          end
        end
      end

      def build_reverse_dependency_graph
        all_entities = Grape::Entity.descendants.select { |e| e.name.present? }

        all_entities.each do |entity|
          exposures = begin
            entity.root_exposure.nested_exposures
          rescue StandardError
            []
          end

          self.class.collect_using_classes(exposures).each do |using_entity|
            next unless using_entity.is_a?(Class) && using_entity < Grape::Entity
            next unless using_entity.name.present?

            @reverse_dependencies[using_entity] << entity
          end

          parent = entity.superclass
          @reverse_dependencies[parent] << entity if parent < Grape::Entity && parent.name.present?
        end
      end

      def compute_usage_radii
        result = {}
        all_entities = (@direct_endpoint_counts.keys + @reverse_dependencies.keys).uniq
        all_entities.each { |entity| result[entity] = usage_radius_for(entity) }
        result
      end

      def usage_radius_for(entity)
        visited = Set.new
        queue = [entity]
        total_endpoints = 0

        loop do
          current = queue.shift
          break unless current
          next if visited.include?(current)

          visited << current
          total_endpoints += @direct_endpoint_counts[current] || 0

          @reverse_dependencies[current]&.each do |dependent|
            queue << dependent unless visited.include?(dependent)
          end
        end

        total_endpoints
      end
    end
  end
end
