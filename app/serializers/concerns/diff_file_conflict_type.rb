# frozen_string_literal: true

module DiffFileConflictType
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  included do
    expose :conflict_type do |diff_file, options|
      conflict_file = conflict_file(options, diff_file)

      next unless conflict_file

      conflict_file.conflict_type(diff_file)
    end
  end

  private

  def conflict_file(options, diff_file)
    strong_memoize(:conflict_file) do
      options[:conflicts] && options[:conflicts][diff_file.new_path]
    end
  end
end
