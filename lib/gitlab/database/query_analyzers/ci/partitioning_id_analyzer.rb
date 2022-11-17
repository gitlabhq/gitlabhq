# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      module Ci
        # The purpose of this analyzer is to detect queries missing partition_id clause
        # when selecting, inserting, updating or deleting data.
        class PartitioningIdAnalyzer < Database::QueryAnalyzers::Base
          PartitionIdMissingError = Class.new(QueryAnalyzerError)

          ROUTING_TABLES = %w[p_ci_builds_metadata].freeze

          class << self
            def enabled?
              ::Feature::FlipperFeature.table_exists? &&
                ::Feature.enabled?(:ci_partitioning_analyze_queries_partition_id_check, type: :ops)
            end

            def analyze(parsed)
              analyze_partition_id_presence(parsed)
            end

            private

            def analyze_partition_id_presence(parsed)
              detected = ROUTING_TABLES & (parsed.pg.dml_tables + parsed.pg.select_tables)
              return if detected.none?

              if insert_query?(parsed)
                return if insert_include_partition_id?(parsed)
              else
                detected_with_selected_columns = parsed_detected_tables(parsed, detected)
                return if partition_id_included?(detected_with_selected_columns)
              end

              ::Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
                PartitionIdMissingError.new(
                  "Detected query against a partitioned table without partition id: #{parsed.sql}"
                )
              )
            end

            def parsed_detected_tables(parsed, routing_tables)
              parsed.pg.filter_columns.each_with_object(Hash.new { |h, k| h[k] = [] }) do |item, hash|
                table_name = item[0] || routing_tables[0]
                column_name = item[1]

                hash[table_name] << column_name if routing_tables.include?(table_name)
              end
            end

            def partition_id_included?(result)
              return false if result.empty?

              result.all? { |_routing_table, columns| columns.include?('partition_id') }
            end

            def insert_query?(parsed)
              parsed.sql.start_with?('INSERT')
            end

            def insert_include_partition_id?(parsed)
              filtered_columns_on_insert(parsed).include?('partition_id')
            end

            def filtered_columns_on_insert(parsed)
              result = parsed.pg.tree.to_h.dig(:stmts, 0, :stmt, :insert_stmt, :cols).map do |h|
                h.dig(:res_target, :name)
              end

              result || []
            end
          end
        end
      end
    end
  end
end
