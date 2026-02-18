# frozen_string_literal: true

module RapidDiffs
  module MergeRequest
    class DiffFilePresenter < Gitlab::View::Presenter::Delegated
      def conflict
        return unless respond_to?(:conflicts) && conflicts

        conflict_data = conflicts[file_path]
        return unless conflict_data

        renamed_file? ? conflict_data[:conflict_type_when_renamed] : conflict_data[:conflict_type]
      end
    end
  end
end
