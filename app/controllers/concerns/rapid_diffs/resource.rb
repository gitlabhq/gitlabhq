# frozen_string_literal: true

module RapidDiffs
  module Resource
    extend ActiveSupport::Concern

    def diff_files_metadata
      return render_404 unless diffs_resource.present?

      render json: {
        diff_files: DiffFileMetadataEntity.represent(diffs_resource.raw_diff_files)
      }
    end

    def diffs_stats
      return render_404 unless diffs_resource.present?

      render json: RapidDiffs::DiffsStatsEntity.represent(
        diffs_resource,
        {
          email_path: email_format_path,
          diff_path: complete_diff_path
        }
      )
    end

    def diff_file
      return render_404 unless diffs_resource.present?

      old_path = diff_file_params[:old_path]
      new_path = diff_file_params[:new_path]
      ignore_whitespace_changes = Gitlab::Utils.to_boolean(diff_file_params[:ignore_whitespace_changes])
      full = Gitlab::Utils.to_boolean(diff_file_params[:full])

      options = {
        expanded: true,
        ignore_whitespace_change: ignore_whitespace_changes
      }

      diff_file = find_diff_file(options, old_path, new_path)
      return render_404 unless diff_file

      if diff_file.whitespace_only? && ignore_whitespace_changes
        options[:ignore_whitespace_change] = false
        diff_file = find_diff_file(options, old_path, new_path)
      end

      if full
        return head :payload_too_large if blob_too_large?(diff_file.blob)

        diff_file.expand_to_full!
      end

      render diff_file_component(diff_file: diff_file, parallel_view: diff_view == :parallel), layout: false
    end

    private

    def diffs_resource(options = {})
      raise NotImplementedError
    end

    attr_reader :environment

    def diff_file_component(base_args)
      ::RapidDiffs::DiffFileComponent.new(**base_args, environment: environment)
    end

    def find_diff_file(extra_options, old_path, new_path)
      with_custom_diff_options do |options|
        options[:paths] = [old_path, new_path].compact
        diffs_resource(**options.merge(extra_options)).diff_files.first
      end
    end

    # When overridden this method should return a path to view diffs in an email-friendly format.
    def email_format_path
      nil
    end

    # When overridden this method should return a path to view the complete diffs in the UI.
    def complete_diff_path
      nil
    end

    def blob_too_large?(blob)
      return false unless blob

      blob.raw_size > Gitlab::CurrentSettings.diff_max_patch_bytes
    end

    def diff_file_params
      params.permit(:old_path, :new_path, :ignore_whitespace_changes, :view, :full)
    end
  end
end
