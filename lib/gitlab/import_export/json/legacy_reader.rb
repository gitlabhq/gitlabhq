# frozen_string_literal: true

module Gitlab
  module ImportExport
    module JSON
      class LegacyReader
        class File < LegacyReader
          def initialize(path, relation_names)
            @path = path
            super(relation_names)
          end

          def valid?
            ::File.exist?(@path)
          end

          private

          def tree_hash
            @tree_hash ||= read_hash
          end

          def read_hash
            ActiveSupport::JSON.decode(IO.read(@path))
          rescue => e
            Gitlab::ErrorTracking.log_exception(e)
            raise Gitlab::ImportExport::Error.new('Incorrect JSON format')
          end
        end

        class User < LegacyReader
          def initialize(tree_hash, relation_names)
            @tree_hash = tree_hash
            super(relation_names)
          end

          def valid?
            @tree_hash.present?
          end

          protected

          attr_reader :tree_hash
        end

        def initialize(relation_names)
          @relation_names = relation_names.map(&:to_s)
        end

        def valid?
          raise NotImplementedError
        end

        def legacy?
          true
        end

        def root_attributes(excluded_attributes = [])
          attributes.except(*excluded_attributes.map(&:to_s))
        end

        def consume_relation(key)
          value = relations.delete(key)

          return value unless block_given?

          return if value.nil?

          if value.is_a?(Array)
            value.each.with_index do |item, idx|
              yield(item, idx)
            end
          else
            yield(value, 0)
          end
        end

        def consume_attribute(key)
          attributes.delete(key)
        end

        def sort_ci_pipelines_by_id
          relations['ci_pipelines']&.sort_by! { |hash| hash['id'] }
        end

        private

        attr_reader :relation_names

        def tree_hash
          raise NotImplementedError
        end

        def attributes
          @attributes ||= tree_hash.slice!(*relation_names)
        end

        def relations
          @relations ||= tree_hash.extract!(*relation_names)
        end
      end
    end
  end
end
