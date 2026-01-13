# frozen_string_literal: true

module API
  module Entities
    module Ci
      class JobArtifactEntry < Grape::Entity
        expose :name, documentation: { type: 'String', example: 'index.html' }

        # rubocop:disable Style/SymbolProc -- API/EntityFieldType doesn't recognize &:path syntax
        expose :path, documentation: { type: 'String', example: 'coverage/index.html' } do |entry|
          entry.path
        end
        # rubocop:enable Style/SymbolProc

        expose :type, documentation: { type: 'String', example: 'file', values: %w[file directory] } do |entry|
          entry.directory? ? 'directory' : 'file'
        end

        expose :size, documentation: { type: 'Integer', example: 12345 },
          if: ->(entry, _) { entry.file? } do |entry|
          entry.metadata[:size]
        end

        expose :mode, documentation: { type: 'String', example: '100644' } do |entry|
          mode_value = entry.metadata[:mode]
          next unless mode_value

          mode_value.to_s.rjust(6, '0')
        end
      end
    end
  end
end
