# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if a spec file exists for any migration using
      # `update_column_in_batches`.
      class UpdateColumnInBatches < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'Migration running `update_column_in_batches` must have a spec file at `%s`.'

        RESTRICT_ON_SEND = %i[update_column_in_batches].freeze

        def on_send(node)
          return unless in_migration?(node)

          spec_path = spec_filename(node)
          return if File.exist?(File.expand_path(spec_path, rails_root))

          add_offense(node, message: format(MSG, spec_path))
        end

        # Used by RuboCop to invalidate its cache if specs change.
        def external_dependency_checksum
          @external_dependency_checksum ||= checksum_filenames('{,ee/}spec/migrations/**/*_spec.rb')
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

        def checksum_filenames(pattern)
          digest = Digest::SHA256.new

          rails_root.glob(pattern) do |path|
            digest.update(path.relative_path_from(rails_root).to_path)
          end

          digest.hexdigest
        end
      end
    end
  end
end
