# frozen_string_literal: true

module DiffFileConflictType
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  included do
    expose :conflict_type do |diff_file, options|
      next unless options[:conflicts]

      diff_file_conflict_type = options[:conflicts][diff_file.new_path]

      next unless diff_file_conflict_type.present?
      next diff_file_conflict_type[:conflict_type] unless diff_file.renamed_file?

      diff_file_conflict_type[:conflict_type_when_renamed]
    end
  end
end
