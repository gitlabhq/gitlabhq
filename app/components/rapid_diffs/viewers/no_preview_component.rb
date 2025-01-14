# frozen_string_literal: true

module RapidDiffs
  module Viewers
    class NoPreviewComponent < ViewerComponent
      include Gitlab::Utils::StrongMemoize

      def self.viewer_name
        'no_preview'
      end

      def change_description
        if @diff_file.new_file?
          _("File added.")
        elsif @diff_file.deleted_file?
          _("File deleted.")
        elsif @diff_file.content_changed? && @diff_file.renamed_file?
          _("File changed and moved.")
        elsif @diff_file.content_changed?
          _("File changed.")
        elsif @diff_file.renamed_file?
          _("File moved.")
        end
      end

      def mode_changed_description
        return unless @diff_file.mode_changed? && !@diff_file.new_file? && !@diff_file.deleted_file?

        message = _('File mode changed from %{from} to %{to}.')
        helpers.safe_format(message, from: @diff_file.a_mode, to: @diff_file.b_mode)
      end

      def no_preview_reason
        if @diff_file.too_large?
          _("File size exceeds preview limit.")
        elsif @diff_file.collapsed?
          _("Preview size limit exceeded, changes collapsed.")
        elsif !@diff_file.diffable?
          _("Preview suppressed by a .gitattributes entry or the file's encoding is unsupported.")
        elsif @diff_file.new_file? || @diff_file.content_changed?
          _("No diff preview for this file type.")
        end
      end

      def expandable?
        @diff_file.diffable_text?
      end

      def important?
        @diff_file.collapsed? || @diff_file.too_large?
      end

      def old_blob_path
        project_blob_path(project, helpers.tree_join(@diff_file.old_content_sha, @diff_file.old_path))
      end

      def new_blob_path
        project_blob_path(project, helpers.tree_join(@diff_file.content_sha, @diff_file.file_path))
      end

      def blob_path
        @diff_file.deleted_file? ? old_blob_path : new_blob_path
      end

      def action_button(**args, &)
        tag.div class: 'rd-no-preview-action' do
          render Pajamas::ButtonComponent.new(**args) do
            yield
          end
        end
      end

      def project
        @diff_file.repository.project
      end
      strong_memoize_attr :project
    end
  end
end
