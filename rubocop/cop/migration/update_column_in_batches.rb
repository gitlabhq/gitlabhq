# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if a spec file exists for any migration using
      # `update_column_in_batches`.
      class UpdateColumnInBatches < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'Migration running `update_column_in_batches` must have a spec file at' \
          ' `%s`.'

        def on_send(node)
          return unless in_migration?(node)
          return unless node.children[1] == :update_column_in_batches

          spec_path = spec_filename(node)

          unless File.exist?(File.expand_path(spec_path, rails_root))
            add_offense(node, location: :expression, message: format(MSG, spec_path))
          end
        end

        private

        def spec_filename(node)
          source_name = node.location.expression.source_buffer.name
          path = Pathname.new(source_name).relative_path_from(rails_root)
          dirname = File.dirname(path)
            .sub(%r{db/(migrate|post_migrate)}, 'spec/migrations')
          filename = File.basename(source_name, '.rb').sub(/\A\d+_/, '')

          File.join(dirname, "#{filename}_spec.rb")
        end

        def rails_root
          Pathname.new(File.expand_path('../../..', __dir__))
        end
      end
    end
  end
end
