module Discussions
  class CommitWithUnresolvedDiscussionsService
    class UpdateActions
      attr_reader :merge_request

      def initialize(merge_request)
        @merge_request = merge_request
      end

      def actions
        insertions
          .group_by(&:path)
          .map do |path, insertions|
            action_for(path, insertions)
          end
      end

      def cache_key
        @cache_key ||= [
          @merge_request.diff_head_sha,
          @merge_request.notes.diff_notes.count,
          @merge_request.notes.diff_notes.maximum(:updated_at)
        ]
      end

      private

      def discussions
        @discussions ||= @merge_request
          .notes.diff_notes.inc_relations_for_view.fresh.discussions
          .select { |d| d.on_text? && d.active? && !d.resolved? && !d.diff_file.deleted_file? && d.position }
      end

      def insertions
        discussions.map { |d| Insertion.new(d) }
      end

      def action_for(path, insertions)
        blob = @merge_request.project.repository.blob_at(@merge_request.diff_head_sha, path)
        content = Inserter.new(blob).insert(insertions)

        {
          action: :update,
          file_path: path,
          content: content
        }
      end
    end
  end
end
